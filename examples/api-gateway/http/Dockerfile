FROM node:14

WORKDIR /app

COPY package*.json .

RUN npm ci

COPY service.js service.js

CMD node service.js