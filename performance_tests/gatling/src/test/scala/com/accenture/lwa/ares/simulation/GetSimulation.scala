package com.accenture.lwa.ares.simulation

import com.accenture.lwa.ares.simulation.scenarios.GetNoAuth
import com.accenture.lwa.ares.simulation.steps.Config

import io.gatling.core.scenario.Simulation

class GetSimulation extends Simulation {

  setUp(GetNoAuth.scn.inject(Config.users).protocols(Config.httpConf))
}