FROM node:14-alpine

# Set working directory
WORKDIR /opt/service/

# Set NODE_ENV to production
ENV NODE_ENV=production

# Attach files required for npm install to container
COPY package.json /opt/service/package.json
COPY package-lock.json /opt/service/package-lock.json

# Install all dependencies
RUN npm ci

# Attach other files to container
COPY kafka /opt/service/kafka
COPY index.js /opt/service/index.js

# Ports
EXPOSE 8000

# Start
CMD ["npm", "start"]
