FROM maven:3-jdk-8

WORKDIR /usr/src/app

COPY . /usr/src/app

CMD mvn gatling:test -Dgatling.simulationClass=com.accenture.lwa.ares.simulation.GetSimulation