FROM n8nio/n8n:1.110.1
#  # Or specify a specific n8n version, e.g., n8nio/n8n:1.82.3

USER root

# Install curl
RUN apk --no-cache add curl

# Install ffmpeg
RUN apk --no-cache add ffmpeg

# Switch back to the n8n user for security
USER node