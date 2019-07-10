describe('Channels', () => {
  ['sse', 'ws'].forEach(type => {
    it(`${type} Public events`, () => {
      cy.visit('http://localhost:3000');
      // "foo":"bar" due to way how Cypress handles escaping of curly braces
      cy.connectAndSendEvents(type, 'mike', 'my.public.event', '"foo":"bar"');
      cy.get('#disconnect-button').click();
    });

    it(`${type} Private events`, () => {
      cy.visit('http://localhost:3000');
      // "name":"mike","foo":"bar" due to way how Cypress handles escaping of curly braces
      cy.connectAndSendEvents(type, 'mike', 'message', '"name":"mike","foo":"bar"');

      cy.get('#message')
        .clear()
        .type('{{}"name":"john","foo":"bar"}')
        .should('have.value', '{"name":"john","foo":"bar"}');
      cy.get('#send-button').click();

      cy.wait(2000)
        .get('#event-log div')
        .should('have.length', 1)
        .first()
        .contains('"name":"mike","foo":"bar"')
        .contains('"eventType":"message"');

      cy.get('#disconnect-button').click();
    });
  });
});
