FROM ubuntu:18.04

# Install required packages and dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential \
    gawk \
    wget \
    git-core \
    diffstat \
    unzip \
    texinfo \
    gcc-multilib \
    g++-multilib \
    build-essential \
    chrpath \
    socat \
    bison \
    curl \
    cpio \
    python3 \
    python3-pip \
    python3-pexpect \
    xz-utils \
    debianutils \
    iputils-ping \
    python3-git \
    python3-jinja2 \
    libegl1-mesa \
    libsdl1.2-dev \
    pylint3 \ 
    xterm \
    locales
# Settings
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8   

ARG DEBIAN_FRONTEND=noninteractive
# RUN echo America/Los_Angeles |  tee /etc/timezone &&  dpkg-reconfigure --frontend noninteractive tzdata

# Define the entry point
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY gosu /bin/gosu
COPY repo_cmd /usr/local/bin/repo
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/repo
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]