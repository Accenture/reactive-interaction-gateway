describe('Subscriptions with JWT auth', () => {
  ['sse', 'ws'].forEach(type => {
    it(`Does ${type} subscription check when creating subscriptions`, () => {
      cy.visit(`/${type}-3-demo-jwt.html`);
      cy.setAndVerifyInput('greeting', 'hello');
      cy.submit();
      cy.assertReceivedEvents('eventList', 'hello');
    });

    it(`Applies ${type} subscription constraints tied with JWT for given event type`, () => {
      cy.visit(`/${type}-demo-jwt-extractors.html`);
      cy.setAndVerifyInput('greeting', 'hello');
      cy.setAndVerifyInput('name', 'john');
      cy.submit();
      cy.assertReceivedEvents('eventList', '"name":"john","greeting":"hello"');
      // John shouldn't receive Mike's events
      cy.setAndVerifyInput('greeting', 'hello');
      cy.setAndVerifyInput('name', 'mike');
      cy.submit();
      cy.assertReceivedEvents('eventList', '"name":"john","greeting":"hello"');
    });

    it(`Creates ${type} subscriptions based on JWT in connection call and applies constraints`, () => {
      cy.visit(`/${type}-demo-jwt-extractors-conn.html`);
      cy.setAndVerifyInput('greeting', 'hello');
      cy.setAndVerifyInput('name', 'john.doe');
      cy.submit();
      cy.assertReceivedEvents('eventList', '"name":"john.doe","greeting":"hello"');
      // John Doe shouldn't receive Mike's events
      cy.setAndVerifyInput('greeting', 'hello');
      cy.setAndVerifyInput('name', 'mike');
      cy.submit();
      cy.assertReceivedEvents(
        'eventList',
        '"name":"john.doe","greeting":"hello"'
      );
    });
  });
});
