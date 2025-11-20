# Use Node.js LTS version as base image
FROM node:20-alpine AS base

# Set working directory
WORKDIR /app

# Install dependencies only when needed
FROM base AS deps
# Copy package files
COPY package.json package-lock.json* ./
# Install all dependencies (Redocly CLI needs all deps)
RUN npm ci && npm cache clean --force

# Production image
FROM base AS runner

# Set environment to production
ENV NODE_ENV=production
ENV PORT=4000

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 redocly

# Copy dependencies from deps stage
COPY --from=deps --chown=redocly:nodejs /app/node_modules ./node_modules

# Copy application files
COPY --chown=redocly:nodejs . .

# Switch to non-root user
USER redocly

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the application
CMD ["npm", "run", "start:prod"]

