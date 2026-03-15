# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies first (layer-cached unless package files change)
COPY package*.json ./
RUN npm ci --legacy-peer-deps

# Copy source and build
COPY . .

# Build-time environment variables (passed via --build-arg or .env)
ARG VITE_APP_FIREBASE_API_KEY
ARG VITE_APP_AUTH_DOMAIN
ARG VITE_APP_FIREBASE_PROJECT_ID
ARG VITE_APP_FIREBASE_MESSAGING_SENDER_ID
ARG VITE_APP_FIREBASE_APP_ID
ARG VITE_APP_FIREBASE_MEASUREMENTID
ARG VITE_APP_DATABASE_URL
ARG VITE_APP_FIREBASE_STORAGE_BUCKET
ARG VITE_APP_FIREBASE_FCM_VAPID_KEY
ARG VITE_APP_USE_EMULATOR

RUN npm run build

# ── Stage 2: Serve ────────────────────────────────────────────────────────────
FROM nginx:1.25-alpine AS production

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# SPA routing: redirect all 404s back to index.html
RUN printf 'server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
