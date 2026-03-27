FROM ubuntu:24.04@sha256:67efaecc0031a612cf7bb3c863407018dbbef0a971f62032b77aa542ac8ac0d2

ARG RUNNER_VERSION="2.331.0"
ARG RUNNER_ARCH="x64"
ARG RUNNER_SHA256="5fcc01bd546ba5c3f1291c2803658ebd3cedb3836489eda3be357d41bfcf28a7"
ARG DEBIAN_FRONTEND=noninteractive

# Add a user named docker
RUN useradd -m docker

# Install runner dependencies and a practical default toolchain for CI jobs.
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        coreutils \
        curl \
        git \
        golang-go \
        jq \
        libffi-dev \
        libssl-dev \
        nodejs \
        npm \
        openssh-client \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Set up the actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -fsSLo actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    && echo "${RUNNER_SHA256}  actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" | sha256sum -c - \
    && tar xzf actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz

# Change ownership to docker user and install dependencies
RUN chown -R docker /home/docker && /home/docker/actions-runner/bin/installdependencies.sh

# Copy the start script and make it executable
COPY --chmod=+x start.sh /start.sh

# Switch to docker user
USER docker

# Define the entrypoint
ENTRYPOINT ["/start.sh"]
