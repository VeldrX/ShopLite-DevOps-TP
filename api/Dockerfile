# Stage 1: Builder
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Copier les dépendances depuis le builder
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Healthcheck (utiliser node car wget n'est pas dans alpine par défaut)
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if(r.statusCode!==200)throw new Error(r.statusCode)})"

EXPOSE 3000

USER node

CMD ["node", "src/server.js"]
