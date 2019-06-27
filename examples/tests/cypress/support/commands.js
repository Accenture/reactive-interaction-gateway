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
