 # My Chain Link — serves the site + API via server.js on Spaceship Hyperlift
# Node 24 LTS: supported until April 2028
FROM node:24-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY . .
# server.js listens on process.env.PORT (Hyperlift sets PORT=8080 by default)
CMD ["node", "server.js"]

