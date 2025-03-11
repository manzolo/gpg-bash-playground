# Use an official Ubuntu image as the base
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    gnupg \
    perl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Copy the script into the container
COPY gpg.sh /usr/local/bin/gpg.sh

# Make the script executable
RUN chmod +x /usr/local/bin/gpg.sh

# Set the working directory
WORKDIR /workspace

RUN mkdir -p /workspace/tmp
ENV EXPORT_DIR=/workspace/tmp

# Set the entrypoint to run the script
ENTRYPOINT ["/usr/local/bin/gpg.sh"]