# plateforme-sim

Plateforme de lancement de simulations

- install ocaml package "omonad" (you can use the ocaml package manager "opam" for this ; about ocaml compiler, the version 4.08.1 is working)
- change directory to /sim/
- in terminal run "bash compil.bash" (on success no message is displayed, and the file "sim.exe" have been created)
- copy /sim/sim.exe to /plateform/src/main/resources/sim.exe
- change directory to /plateform/
- install package "redis". If success you should have the command "redis-server" available from your terminal
- in terminal run "redis-server src/main/resources/redis.conf &" (on failure about address already in use, try to set another port like 6381, you have to set it in src/main/resources/redis.conf line 50, and in /src/main/scala/myservice.scala line 233)
- in terminal run "sbt compile" (it can take a while since it could need to download and install scala packages, on success it prints "[success]...")
- in terminal run "sbt run" (on success there is no error messages)
- browse http://localhost:8080/client for the UI (if it seems to fail, check the terminal for error messages from sbt)
- when you are done close UI and ctrl+c the sbt 
- then run in terminal "redis-cli -h localhost -p 6380 shutdown" (if you used a differend port in redis.conf you have to use a different port here also)
- if you want you can delete src/main/resource/redis/dump.rdb to delete the database entries

