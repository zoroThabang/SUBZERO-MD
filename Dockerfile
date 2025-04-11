# Use Node.js LTS with Debian Bullseye (more stable than Buster)
FROM node:lts-bullseye

# Set non-root user
USER root

# Install system dependencies with retry logic
RUN for i in {1..5}; do \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        webp \
        git \
        libavcodec-extra && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    break || sleep 15; \
    done

# Switch to non-root user
USER node

# Clone your bot repository
RUN git clone https://github.com/mrfrankofcc/SUBZERO-MD.git /home/node/SUBZERO-MD

WORKDIR /home/node/SUBZERO-MD

# Fix permissions (safer than 777)
RUN chown -R node:node . && \
    chmod -R 755 .

# Install Node.js dependencies
COPY package.json yarn.lock ./
RUN yarn install --network-concurrency 1 --production --ignore-engines --frozen-lockfile || \
    (yarn cache clean && yarn install --network-concurrency 1 --production --ignore-engines)

# Copy app files
COPY . .

# Expose the bot port
EXPOSE 7860

# Set production environment
ENV NODE_ENV=production

# Run with PM2 (Docker-optimized mode)
CMD ["pm2-runtime", "start", "index.js", "--name", "SUBZERO-MD"]
