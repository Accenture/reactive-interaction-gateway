package com.accenture.lwa.ares.simulation

import com.accenture.lwa.ares.simulation.scenarios.BroadcastBurstWs
import com.accenture.lwa.ares.simulation.steps.Config

import io.gatling.core.scenario.Simulation

class WsBurstBroadcastSimulation extends Simulation {

  setUp(BroadcastBurstWs.scn.inject(Config.users).protocols(Config.httpConf))
}