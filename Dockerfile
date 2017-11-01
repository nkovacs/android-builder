FROM ubuntu:16.04 as base

# Install deps
# jdk 7 and 8 for android
# lib32z1 and lib32stdc++6 for android
# locales to set locale
RUN echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 86F44E2A && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-7-jdk \
        openjdk-8-jdk \
        lib32z1 \
        lib32stdc++6 \
        locales \
    && rm -rf /var/lib/apt/lists/*

# Set utf-8 locale because otherwise gradle daemon will crash if env contains non-ascii characters.
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

FROM base as install

# Install deps
# curl to download the sdk tools
# unzip to unzip the sdk tools
# expect to accept the license
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        unzip \
        expect \
    && rm -rf /var/lib/apt/lists/*

# Download Android SDK
RUN cd /opt \
    && mkdir -p android-sdk-linux \
    && curl -o android-tools.zip https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip \
    && unzip  android-tools.zip -d android-sdk-linux \
    && rm -f android-tools.zip \
    && chown -R root:root android-sdk-linux

RUN mkdir -p /opt/tools
COPY android-accept-licenses.sh /opt/tools/
RUN chmod a+x /opt/tools/android-accept-licenses.sh

# Update tools
RUN ["/opt/tools/android-accept-licenses.sh", "sdkmanager tools"]

WORKDIR /opt/tools/

COPY semver_bash /opt/tools/semver_bash
COPY build.sh /opt/tools/
RUN chmod a+x build.sh

RUN ./build.sh
RUN /opt/tools/android-accept-licenses.sh "sdkmanager $(cat toinstall)" |  tr '\r' '\n' | uniq

FROM base

COPY --from=install /opt/android-sdk-linux /opt/android-sdk-linux

RUN mkdir -p /opt/workspace
WORKDIR /opt/workspace

RUN adduser testuser --disabled-login
USER testuser
