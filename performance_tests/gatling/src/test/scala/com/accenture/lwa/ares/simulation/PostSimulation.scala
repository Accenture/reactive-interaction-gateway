package com.accenture.lwa.ares.simulation

import com.accenture.lwa.ares.simulation.scenarios.PostNoAuth
import com.accenture.lwa.ares.simulation.steps.Config

import io.gatling.core.scenario.Simulation

class PostSimulation extends Simulation {

  setUp(PostNoAuth.scn.inject(Config.users).protocols(Config.httpConf))
}