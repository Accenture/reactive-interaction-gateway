describe('Websocket', () => {
  describe('No auth', () => {
    it('Basic', () => {
      cy.visit('/ws-demo.html');
      cy.testWithNameAndGreeting();
    });

    it('With constraints', () => {
      cy.visit('/ws-demo-simple-extractors.html');
      cy.testWithNameAndGreeting({ name: 'john' });
      cy.testWithNameAndGreeting({ name: 'mike', ne: true });
    });
  });

  describe('JWT', () => {
    it('With jwt', () => {
      cy.visit('/ws-demo-jwt.html');
      cy.testWithNameAndGreeting();
    });

    it('With jwt & constraints', () => {
      cy.visit('/ws-demo-jwt-extractors.html');
      cy.testWithNameAndGreeting({ name: 'john' });
      cy.testWithNameAndGreeting({ name: 'mike', ne: true });
    });

    it('With jwt & constraints & connect', () => {
      cy.visit('/ws-demo-jwt-extractors-conn.html');
      cy.testWithNameAndGreeting({ name: 'john.doe' });
      cy.testWithNameAndGreeting({ name: 'mike', ne: true });
    });
  });
});
