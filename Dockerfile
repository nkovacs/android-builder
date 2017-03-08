FROM ubuntu:16.04

RUN apt-get update && apt-get install -y --no-install-recommends openjdk-8-jdk curl expect lib32stdc++6 lib32z1 \
    && rm -rf /var/lib/apt/lists/*

# Download Android SDK
RUN cd /opt \
    && curl -o android-sdk.tgz http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz \
    && tar xzf android-sdk.tgz \ 
    && rm -f android-sdk.tgz \
    && chown -R root:root android-sdk-linux

RUN apt-get purge -y --auto-remove curl

RUN mkdir -p /opt/tools
COPY android-accept-licenses.sh /opt/tools/
RUN chmod a+x /opt/tools/android-accept-licenses.sh

ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --all --force --no-ui --filter platform-tools,build-tools-25.0.2,build-tools-25.0.1,build-tools-25.0.0,build-tools-24.0.3,build-tools-24.0.2,build-tools-24.0.1,build-tools-24.0.0,build-tools-23.0.3,build-tools-23.0.2,build-tools-23.0.1,android-25,android-24,android-23,extra-android-support,extra-android-m2repository"]

RUN mkdir -p /opt/workspace
WORKDIR /opt/workspace

RUN adduser testuser --disabled-login
USER testuser
