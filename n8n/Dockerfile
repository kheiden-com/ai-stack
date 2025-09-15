FROM n8nio/n8n:1.110.1
#  # Or specify a specific n8n version, e.g., n8nio/n8n:1.82.3

USER root

# Install packages for the Execute node
RUN apk --no-cache add curl
RUN apk --no-cache add ffmpeg
RUN apk --no-cache add rsync
RUN apk --no-cache add sshpass

# Create n8n data directory for the node user
RUN mkdir -p /home/node/.n8n && chown node:node /home/node/.n8n

# Switch back to the n8n user for security
USER node

# Copy the pre-configured workflow(s) into the user's n8n directory
COPY workflows/ /home/node/.n8n/workflows/