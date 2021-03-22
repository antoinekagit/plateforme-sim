import scala.concurrent.{ Future, ExecutionContextExecutor }
import scala.concurrent.duration._

import scala.util.{ Try, Success, Failure }

import akka.actor.{ Actor, ActorRef, Props }

import akka.pattern.{ ask, pipe }
import akka.util.Timeout

import akka.event.Logging

import spray.{ routing => sr }
import spray.{ http => sh }

import spray.{ json => sj }
import spray.json._
import spray.{ httpx => shx }

import sh.MediaTypes._

import scala.sys.process.{ ProcessIO, Process }
import java.io.{ BufferedReader, InputStreamReader, PrintWriter }
import java.nio.file.{ Files, Paths }
import java.nio.file.attribute.PosixFilePermissions

import redis.RedisClient

import MyJsonProtocol._


case class AskSimPeriods (alias:String, start:Int, nb:Int)
case class SAddSim (alias:String)
case class StorePeriod (alias:String, period:Int, data:Map[String,Float])
case class AskNbStored (alias:String)

trait AnsSimPeriodsTrait
case class AnsSimPeriods (data:Map[String,Map[String,Float]])
extends AnsSimPeriodsTrait
case class AnsSimPeriodsNotReady (missing:Int) extends AnsSimPeriodsTrait


class SimActor (alias:String, redisActor:ActorRef, nbStoredArg:Int)
    extends Actor {

  implicit val timeout = Timeout(5.seconds)
  implicit def ec = context.dispatcher

  val log = Logging(context.system, this)

  var processInput : PrintWriter = null
  var processOutput : BufferedReader = null
  val processIO = new ProcessIO (
    procIn => processInput = new PrintWriter(procIn),
    procOut => processOutput =
      new BufferedReader (new InputStreamReader (procOut)),
    _ => ())
		
  val simExecPath =
    Files.createTempFile ("sim", ".exe",
      PosixFilePermissions.asFileAttribute(
        PosixFilePermissions.fromString("rwx------")))
   
  val simStream = getClass.getResourceAsStream("/sim.exe")		
  Files.write(simExecPath, simStream.readAllBytes)

  simExecPath.toFile.setWritable(false)

  val process : Process =
    Process(simExecPath.toString + " interactif").run(processIO)


  def exportPeriod : Map[String,Float] = {
    def getLine :Array[Float] = processOutput.readLine split ' ' map (_.toFloat)
    val cash = getLine
    val biens = getLine
    val prix = getLine
    val achats = getLine
    val fin = processOutput.readLine
    Map(
      "cashBank" -> cash(0),
      "cashFirms" -> cash(1),
      "cashMenages" -> cash(2),
      "biensFirms" -> biens(0),
      "biensMenages" -> biens(1),
      "biensProduits" -> biens(2),
      "prixMoyenFirms" -> prix(0),
      "nbAchats" -> achats(0)
    )

  }

  //var itScamel:Iterator[SimExport] = computIt
  var nbTarget = 0
  var nbStored = nbStoredArg
  var loading = false

  case class StartLoad ()
  case class NextLoad ()
  case class LoadedOne ()

  def receive = {
    case StartLoad() =>
      if (! loading) {
        loading = true
        self ! NextLoad() }
    case LoadedOne() =>
      nbStored = nbStored + 1
      self ! NextLoad()
    case NextLoad() =>
      val diff = nbTarget - nbStored
      if (diff <= 0) loading = false
      else {
        val me = self
        val period = nbStored + 1
        Future {
          processInput println "next"
          processInput.flush
          exportPeriod
        } flatMap { loaded =>
          ask(redisActor, StorePeriod(alias, period, loaded))(1.seconds)
        } map { _ =>
          me ! LoadedOne()
        }}
    case AskSimPeriods(_, start, nb) =>
      val diff = (start + nb) - nbStored
      val fut = {
        if (diff > 0) {
          nbTarget = nbStored + diff
          self ! StartLoad()
          Future { AnsSimPeriodsNotReady(diff) }}
        else ask(redisActor, AskSimPeriods(alias, start, nb))(1.seconds)
      }
      fut pipeTo sender
    case other => log.error(s"received $other")
  }
}

class GestionnaireSim (redisActor:ActorRef) extends Actor {

  implicit def ec = context.dispatcher

  var simActors = Map.empty[String,ActorRef]

  def newSimActor (alias:String) :Future[ActorRef] =
    ask(
      redisActor, AskNbStored(s"alias:$alias"))(1.seconds
    ).mapTo[Option[Int]] flatMap {
      case Some(nbStored) => Future { nbStored }
      case None => ask(redisActor, SAddSim(alias))(1.seconds) map { _ => 0 }
    } map { nbStored =>
      val newSimActor = context.actorOf(Props(classOf[SimActor],
        alias, redisActor, nbStored ))
      simActors = simActors updated (alias, newSimActor)
      newSimActor
    }

  def receive = {
    case AskSimPeriods(alias, start, nb) =>
      (simActors get alias match {
        case None => newSimActor(alias)
        case Some(simActor) => Future { simActor }
      }) flatMap { simActor =>
        ask(simActor, AskSimPeriods(alias, start, nb))(5.seconds)
      } pipeTo sender
  }
}

class RedisActor (redis:RedisClient) extends Actor {
  implicit def ec = context.dispatcher

  val log = Logging(context.system, this)

  def receive = {
    case StorePeriod(alias, period, data) =>
      redis.hmset(s"period:$alias:$period", data) flatMap { _ =>
        redis.incr(s"alias:$alias")
      } map (_ => ()) pipeTo sender
    case AskSimPeriods(alias, start, nb) =>
      val seqFutData = (start + 1 to start + nb) map { period =>
        redis.hgetall(s"period:$alias:$period") }
      Future.sequence(seqFutData) map { vmb =>
        val vmf = vmb map (_ map { case (key, value) =>
          (key, value.utf8String.toFloat) } )
        val periods = (start + 1 to start + nb) map (_.toString)
        AnsSimPeriods(periods.zip(vmf).toMap)
      } pipeTo sender
    case AskNbStored(alias) =>
      redis.get(alias) map (_.map (_.utf8String.toInt)) pipeTo sender
    case SAddSim(alias) => redis.set(s"alias:$alias", 0) pipeTo sender
    case "ping" => redis.ping pipeTo sender
    case other => log.error(s"received $other")
  }
}

trait MyService extends sr.HttpService {

  implicit def ec:ExecutionContextExecutor
  val gestionnaireSim:ActorRef
  val gestionnaireRedis:ActorRef

  val defaultAlias :String = "defaultSim"

  val myRoute =
    path("sim") { jsonpWithParameter("callback") { get {
      parameter("start".as[Int]) { start =>
        parameter("nb".as[Int]) { nb =>
          validate(start >= 0, "start must be >= 0") {
            validate(nb >= 1, "nb must be >= 1") { complete {
              ask(gestionnaireSim,
                AskSimPeriods(defaultAlias, start, nb)
              )(5.seconds).mapTo[AnsSimPeriodsTrait]
            }}}}}}}
    } ~ pathPrefix("client") {
      pathEnd { redirect("client/", spray.http.StatusCodes.PermanentRedirect) } ~
      pathSingleSlash { getFromResource("client/index.html") } ~
      getFromResourceDirectory("client/")
    } ~ pathPrefix("redis") {
      path("ping") { get { complete {
        ask(gestionnaireRedis, "ping")(1.seconds).mapTo[String] }}
      }
    } 
}

class MyServiceActor extends Actor with MyService {

  def actorRefFactory = context
  def ec = actorRefFactory.dispatcher

  val gestionnaireRedis =
    actorRefFactory.actorOf(Props(classOf[RedisActor],
      RedisClient("localhost", 6380)(actorRefFactory)), "gestionnaireRedis")

  val gestionnaireSim = actorRefFactory.actorOf(
    Props(classOf[GestionnaireSim], gestionnaireRedis), "gestionnaireSim")
  def receive = runRoute(myRoute)

}

