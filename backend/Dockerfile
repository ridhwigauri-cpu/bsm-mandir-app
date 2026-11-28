FROM node:20-bookworm-slim

# PDF के लिए Chromium + भारतीय फ़ॉन्ट
RUN apt-get update && apt-get install -y --no-install-recommends \
      chromium fonts-noto-core fonts-noto-extra ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV CHROMIUM_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_DOWNLOAD=1

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev || npm install --omit=dev
COPY . .

ENV NODE_ENV=production
EXPOSE 8080
CMD ["node", "src/server.js"]
