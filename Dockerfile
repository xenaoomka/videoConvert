# Use the Alpine Linux base image
FROM alpine:latest

# Set the working directory
WORKDIR /app

# Install FFmpeg and any other necessary packages
RUN apk update && apk add --no-cache ffmpeg

# Create a directory for persistent storage
VOLUME /app/content

# Copy the application files into the container
COPY videoConvert.sh /app
RUN mkdir /app/content/output;mkdir /app/content/archive
RUN chmod 755 /app/videoConvert.sh

# Create a non-root user
RUN addgroup -g 1000 appuser && adduser -u 1000 -G appuser -D appuser
USER appuser

# Define any environment variables, if needed
ENV ENV_VAR_NAME=dev

# Expose any necessary ports
#EXPOSE 8080

# Start the application or specify the default command
ENTRYPOINT ["/app/videoConvert.sh"]
