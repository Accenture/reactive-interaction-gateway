package com.accenture.lwa.ares.simulation

import com.accenture.lwa.ares.simulation.scenarios.GetWithAuth
import com.accenture.lwa.ares.simulation.steps.Config

import io.gatling.core.scenario.Simulation

class GetAuthSimulation extends Simulation {

  setUp(GetWithAuth.scn.inject(Config.users).protocols(Config.httpConf))
}