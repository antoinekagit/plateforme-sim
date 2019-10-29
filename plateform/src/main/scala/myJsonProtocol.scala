import spray.json._
import spray.{ httpx => shx }

object MyJsonProtocol extends DefaultJsonProtocol with shx.SprayJsonSupport {

  implicit object FloatFormat extends RootJsonFormat[Float] {
    def read (value:JsValue) = deserializationError("reader")
    def write (f:Float) =
      if (f == Float.MaxValue || f == Float.MinValue) JsNull
      else JsNumber(f) }

  implicit object IntFormat extends RootJsonFormat[Int] {
    def read (value:JsValue) = deserializationError("reader")
    def write (i:Int) =
      if (i == Int.MaxValue || i == Int.MinValue) JsNull
      else JsNumber(i) }

  implicit val ansPeriodsFormat = jsonFormat1(AnsSimPeriods)
  implicit val periodsNotReadyFormat = jsonFormat1(AnsSimPeriodsNotReady)
  implicit object AnsSimPeriodsFormat
      extends RootJsonFormat[AnsSimPeriodsTrait] {
    def read (value:JsValue) = deserializationError("reader")
    def write (ans:AnsSimPeriodsTrait) = ans match {
      case a:AnsSimPeriods => JsObject("periods" -> a.data.toJson)
      case a:AnsSimPeriodsNotReady => JsObject("periodsNotReady" -> a.toJson) }}
}
