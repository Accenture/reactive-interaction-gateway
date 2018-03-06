package com.accenture.lwa.ares.simulation

import com.accenture.lwa.ares.simulation.scenarios.ConnectWs
import com.accenture.lwa.ares.simulation.steps.Config

import io.gatling.core.scenario.Simulation

class WsMaxUsersSimulation extends Simulation {

  setUp(ConnectWs.scn.inject(Config.users).protocols(Config.httpConf))
}