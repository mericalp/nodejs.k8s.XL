FROM node:16

WORKDIR /app

COPY package*.json ./
COPY models/ ./models/
COPY server.js .

RUN npm install

EXPOSE 5001

CMD ["node", "server.js"]