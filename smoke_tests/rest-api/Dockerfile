FROM node:14-alpine

WORKDIR /opt/apps/nodejs-simple-rest-api/

ENV NODE_ENV=production

COPY package.json /opt/apps/nodejs-simple-rest-api/package.json
COPY package-lock.json /opt/apps/nodejs-simple-rest-api/package-lock.json

RUN npm ci

COPY src /opt/apps/nodejs-simple-rest-api/src
COPY index.js /opt/apps/nodejs-simple-rest-api/index.js

EXPOSE 8000

CMD ["npm", "start"]
