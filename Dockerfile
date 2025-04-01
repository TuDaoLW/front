# Build stage
FROM node:16-alpine as build-stage

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built app from build stage
COPY --from=build-stage /app/dist /usr/share/nginx/html

# Create necessary directories with proper permissions
RUN mkdir -p /var/cache/nginx /var/run && \
    chown -R nginx:nginx /var/cache/nginx /var/run && \
    chmod -R 755 /var/cache/nginx /var/run && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chmod 755 /usr/share/nginx/html && \
    touch /usr/share/nginx/html/config.js && \
    chown nginx:nginx /usr/share/nginx/html/config.js && \
    chmod 644 /usr/share/nginx/html/config.js

# Add health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Expose port 8080
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]