Cypress.Commands.add('setAndVerifyInput', (id, value) => {
  cy.get(`#${id}`)
    .type(value)
    .should('have.value', value);
});

Cypress.Commands.add('submit', () => {
  cy.get('[type="submit"]').click();
});

Cypress.Commands.add('connect', transportProtocol => {
  // create connection to sse/ws
  cy.get(`#${transportProtocol}-radio`).click();
});

Cypress.Commands.add('disconnect', () => {
  // disconnect from sse/ws
  cy.get('#disconnect-button').click();
});

Cypress.Commands.add('subscribe', (name, eventType) => {
  // create subscription
  cy.get('#username')
    .type(name)
    .should('have.value', name);
  cy.get('#event-type-inbound')
    .type(eventType)
    .should('have.value', eventType);
  cy.get('#connect-button').click();
  cy.contains(
    '#subscription-notification',
    `You are now subscribed to ${eventType} event type. Try to send some event.`
  );
});

Cypress.Commands.add('sendEvent', (eventType, message) => {
  // send event
  cy.get('#event-type-outbound')
    .clear()
    .type(eventType)
    .should('have.value', eventType);
  cy.get('#message')
    .clear()
    .type(`{{}${message}}`)
    .should('have.value', `{${message}}`);
  cy.get('#send-button').click();
});

Cypress.Commands.add('assertNewestEventContainsMessage', (element, message) => {
  // assert number and content of received events
  cy.get(`#${element} > li`, {timeout: 30000})
    .should('be.visible')
    .first()
    .contains(message)
});

Cypress.Commands.add('assertSingleNewEventContainsMessage', (element, message) => {
  // assert number and content of received events
  cy.get(`#${element}`, {timeout: 30000})
    .should('have.length', 1)
    .first()
    .contains(new RegExp(message, 'g'));
});
