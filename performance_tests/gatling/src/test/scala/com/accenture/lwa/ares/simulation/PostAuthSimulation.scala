package com.accenture.lwa.ares.simulation

import com.accenture.lwa.ares.simulation.scenarios.PostWithAuth
import com.accenture.lwa.ares.simulation.steps.Config

import io.gatling.core.scenario.Simulation

class PostAuthSimulation extends Simulation {

  setUp(PostWithAuth.scn.inject(Config.users).protocols(Config.httpConf))
}