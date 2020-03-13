FROM node:10-alpine

WORKDIR /opt/apps/nodejs-simple-rest-api/

ENV NODE_ENV=production

COPY package.json /opt/apps/nodejs-simple-rest-api/package.json

RUN npm i --no-package-lock

COPY src /opt/apps/nodejs-simple-rest-api/src
COPY index.js /opt/apps/nodejs-simple-rest-api/index.js

EXPOSE 8000

CMD ["npm", "start"]
