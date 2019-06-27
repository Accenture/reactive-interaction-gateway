describe('Subscriptions with no auth', () => {
  ['sse', 'ws'].forEach(type => {
    it(`${type} Creates connection and subscriptions`, () => {
      cy.visit(`/${type}-demo.html`);
      cy.testWithNameAndGreeting();
    });

    it(`${type} Creates connection and subscriptions within a same call`, () => {
      cy.visit(`/${type}-demo-single-call.html`);
      cy.testWithNameAndGreeting();
    });

    it(`${type} Applies subscription constraints for given event type`, () => {
      cy.visit(`/${type}-demo-simple-extractors.html`);
      cy.testWithNameAndGreeting({ name: 'john' });
      cy.testWithNameAndGreeting({ name: 'mike', ne: true });
    });
  });
});
