FROM node:20-alpine

WORKDIR /app

# Install curl for healthchecks
RUN apk add --no-cache curl

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Create data directory
RUN mkdir -p /data

EXPOSE 3000

USER node

CMD ["node", "index.js"]
