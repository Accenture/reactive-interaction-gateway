describe('Subscriptions with JWT auth', () => {
  ['sse', 'ws'].forEach(type => {
    it(`${type} Does subscription check when creating subscriptions`, () => {
      cy.visit(`/${type}-demo-jwt.html`);
      cy.testWithNameAndGreeting();
    });

    it(`${type} Applies subscription constraints tied with JWT for given event type`, () => {
      cy.visit(`/${type}-demo-jwt-extractors.html`);
      cy.testWithNameAndGreeting({ name: 'john' });
      cy.testWithNameAndGreeting({ name: 'mike', ne: true });
    });

    it(`${type} Creates subscriptions based on JWT in connection call and applies constraints`, () => {
      cy.visit(`/${type}-demo-jwt-extractors-conn.html`);
      cy.testWithNameAndGreeting({ name: 'john.doe' });
      cy.testWithNameAndGreeting({ name: 'mike', ne: true });
    });
  });
});
