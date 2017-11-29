import { sign } from 'jsonwebtoken';
import { v4 } from 'uuid';
import { JWT_SECRET_KEY, JWT_ROLES_FIELD, JWT_USER_FIELD } from '../constants';

/**
 * Generates JWT with required fields
 * @param   {string} username
 * @param   {array} levels
 * @returns {string} generated JWT
 */
export const getJwtToken = (username, levels) => {
    // Populates claims with required fields
    const claims = {};
    claims[JWT_USER_FIELD] = username;
    claims[JWT_ROLES_FIELD] = levels;

    return sign(claims, JWT_SECRET_KEY, { expiresIn: '60m', jwtid: v4() });
};

/**
 * Calls external service which produces message to Kafka
 * @param   {object} message
 * @returns {promise}
 */
export const produceKafkaMessageAsync = (message) => {
    return fetch('/produce', {
        method: 'POST',
        body: JSON.stringify(message),
        headers: { 'Content-Type': 'application/json' },
    })
    .then((response) => response.json());
};