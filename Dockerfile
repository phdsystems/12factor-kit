# 12-Factor Reviewer - Docker Image
FROM alpine:3.19

LABEL maintainer="PHD Systems"
LABEL description="12-Factor App Compliance Reviewer Tool"

# Install dependencies
RUN apk add --no-cache \
    bash \
    git \
    grep \
    findutils \
    python3 \
    py3-pip \
    nodejs \
    npm

# Create app directory
WORKDIR /app

# Copy the assessment tool and libraries
COPY bin/ /app/bin/
COPY src/ /app/src/
COPY config/ /app/config/

# Make executable
RUN chmod +x /app/bin/twelve-factor-reviewer

# Add to PATH
ENV PATH="/app/bin:${PATH}"

# Set the working directory for assessments
WORKDIR /project

# Default command
ENTRYPOINT ["twelve-factor-reviewer"]
CMD ["."]