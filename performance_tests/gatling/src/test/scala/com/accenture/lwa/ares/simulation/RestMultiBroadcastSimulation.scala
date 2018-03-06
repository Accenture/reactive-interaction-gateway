package com.accenture.lwa.ares.simulation

import com.accenture.lwa.ares.simulation.scenarios.BroadcastLoadRest
import com.accenture.lwa.ares.simulation.steps.Config

import io.gatling.core.scenario.Simulation

class RestMultiBroadcastSimulation extends Simulation {

  setUp(BroadcastLoadRest.scn.inject(Config.users).protocols(Config.httpConf))
}