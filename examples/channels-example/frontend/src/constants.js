// configurable env vars, same names as Reactive Interaction Gateway is using
export const PRIVILEGED_ROLES = process.env.PRIVILEGED_ROLES || 'admin';
export const JWT_ROLES_FIELD = process.env.JWT_ROLES_FIELD || 'levels';
export const JWT_USER_FIELD = process.env.JWT_USER_FIELD || 'username';
export const JWT_SECRET_KEY = process.env.JWT_SECRET_KEY || 'mysecret';
export const KAFKA_USER_FIELD = process.env.KAFKA_USER_FIELD || 'username';