describe('Subscriptions with no auth', () => {
  ['sse', 'ws', 'lp'].forEach(type => {
    it(`Creates ${type} connection and subscriptions`, () => {
      cy.visit(`/${type}-1-demo.html`);
      cy.setAndVerifyInput('greeting', 'hello');
      cy.submit();
      cy.assertNewestEventInEventList('hello');
    });

    it(`Creates ${type} connection and subscriptions within a same call`, () => {
      cy.visit(`/${type}-demo-single-call.html`);
      cy.setAndVerifyInput('greeting', 'hello');
      cy.submit();
      cy.assertNewestEventInEventList('hello');
    });

    it(`Applies ${type} subscription constraints for given event type`, () => {
      cy.visit(`/${type}-2-demo-simple-extractors.html`);
      cy.setAndVerifyInput('greeting', 'hello');
      cy.setAndVerifyInput('name', 'john');
      cy.submit();
      cy.assertNewestEventInEventList('"name":"john","greeting":"hello"');
      // John shouldn't receive Mike's events
      cy.setAndVerifyInput('greeting', 'hello');
      cy.setAndVerifyInput('name', 'mike');
      cy.submit();
      cy.assertNewestEventInEventList('"name":"john","greeting":"hello"');
    });
  });
});
