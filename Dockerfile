# My Chain Link — serves the site + API via server.js on Spaceship Hyperlift
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY . .
# server.js listens on process.env.PORT (Hyperlift sets PORT=8080 by default)
CMD ["node", "server.js"]
