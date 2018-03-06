package com.accenture.lwa.ares.simulation

import com.accenture.lwa.ares.simulation.scenarios.BroadcastLoadWs
import com.accenture.lwa.ares.simulation.steps.Config

import io.gatling.core.scenario.Simulation

class WsMultiBroadcastSimulation extends Simulation {

  setUp(BroadcastLoadWs.scn.inject(Config.users).protocols(Config.httpConf))
}