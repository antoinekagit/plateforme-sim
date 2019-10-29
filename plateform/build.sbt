organization  := "com.example"
version       := "0.1"

fork in run := true
cancelable in Global := true


scalacOptions := Seq(
  "-unchecked", "-deprecation", "-feature", "-encoding", "utf8")

scalaVersion := "2.11.7"

libraryDependencies ++= {
  val akkaV = "2.3.9"
  val sprayV = "1.3.3"
  Seq(
    "io.spray"            %%  "spray-can"     % sprayV,
    "io.spray"            %%  "spray-routing" % sprayV,
    "io.spray"            %%  "spray-testkit" % sprayV  % "test",
    "io.spray"            %%  "spray-json"    % "1.3.2",
    "com.typesafe.akka"   %%  "akka-actor"    % akkaV,
    "com.typesafe.akka"   %%  "akka-testkit"  % akkaV   % "test",
    "org.specs2"          %%  "specs2-core"   % "2.3.11" % "test",
    "com.github.etaty"    %%  "rediscala"     % "1.6.0"
  )
}

Revolver.settings
