import scala.concurrent.duration._

import akka.actor.{ ActorSystem, Props }
import akka.io.IO
import akka.pattern.ask
import akka.util.Timeout

import spray.can.Http

object Boot {
  def main (args:Array[String]) :Unit = {

    implicit val system = ActorSystem("on-spray-can")

    val service = system.actorOf(Props[MyServiceActor], "demo-service")

    implicit val timeout = Timeout(5.seconds)

    IO(Http) ? Http.Bind(service, interface = "localhost", port = 8080)

  }
}
