describe('Server-sent events', () => {
  describe('No auth', () => {
    it('Basic', () => {
      cy.visit('/sse-demo.html');
      cy.testWithNameAndGreeting();
    });

    it('With constraints', () => {
      cy.visit('/sse-demo-simple-extractors.html');
      cy.testWithNameAndGreeting({ name: 'john' });
      cy.testWithNameAndGreeting({ name: 'mike', ne: true });
    });
  });

  describe('JWT', () => {
    it('With jwt', () => {
      cy.visit('/sse-demo-jwt.html');
      cy.testWithNameAndGreeting();
    });

    it('With jwt & constraints', () => {
      cy.visit('/sse-demo-jwt-extractors.html');
      cy.testWithNameAndGreeting({ name: 'john' });
      cy.testWithNameAndGreeting({ name: 'mike', ne: true });
    });

    it('With jwt & constraints & connect', () => {
      cy.visit('/sse-demo-jwt-extractors-conn.html');
      cy.testWithNameAndGreeting({ name: 'john.doe' });
      cy.testWithNameAndGreeting({ name: 'mike', ne: true });
    });
  });
});
