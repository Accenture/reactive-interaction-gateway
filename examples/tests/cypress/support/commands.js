Cypress.Commands.add(
  'testWithNameAndGreeting',
  ({ name, greeting = 'hello', ne = false } = {}) => {
    if (name) {
      cy.get('#name')
        .type(name)
        .should('have.value', name);
    }

    cy.get('#greeting')
      .type(greeting)
      .should('have.value', greeting);

    cy.get('[type="submit"]').click();

    if (ne) {
      // wait 2 seconds, there should be no new event
      cy.wait(2000)
        .get('#eventList li')
        .should('have.length', 1);
      return;
    }

    const event = name ? `{"name":"${name}","greeting":"${greeting}"}` : greeting;
    cy.get('#eventList li').should('have.length', 1);
    cy.get('#eventList li')
      .first()
      .contains(event);
  }
);

Cypress.Commands.add(
  'connectAndSendEvents',
  (transportProtocol, name, eventType, message) => {
    cy.get(`#${transportProtocol}-radio`).click();

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

    cy.get('#event-type-outbound')
      .type(eventType)
      .should('have.value', eventType);
    cy.get('#message')
      .type(`{{}${message}}`)
      .should('have.value', `{${message}}`);
    cy.get('#send-button').click();

    cy.get('#event-log div')
      .should('have.length', 1)
      .first()
      .contains(message)
      .contains(`"eventType":"${eventType}"`);
  }
);
