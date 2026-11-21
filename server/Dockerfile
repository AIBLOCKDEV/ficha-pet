FROM node:20-alpine
WORKDIR /usr/src/app
COPY package.json ./
COPY server.js schema.sql ./
RUN mkdir -p data
EXPOSE 3000
CMD ["node", "server.js"]
