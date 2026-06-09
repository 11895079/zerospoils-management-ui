# Development Dockerfile for Worker
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

EXPOSE 3002

# Use node to run compiled JavaScript, not tsx
CMD ["node", "dist/worker.js"]
