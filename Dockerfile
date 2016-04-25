FROM ubuntu:16.04

RUN apt-get update && apt-get install -y --no-install-recommends openjdk-8-jdk curl expect \
    && rm -rf /var/lib/apt/lists/*

# Download Android SDK
RUN cd /opt \
    && curl -o android-sdk.tgz http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz \
    && tar xzf android-sdk.tgz \ 
    && rm -f android-sdk.tgz

RUN apt-get purge -y --auto-remove curl

RUN mkdir -p /opt/tools
COPY android-accept-licenses.sh /opt/tools/
RUN chmod a+x /opt/tools/android-accept-licenses.sh

ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --all --force --no-ui --filter platform-tools,tools,build-tools-23.0.3,android-23,extra-android-support"]

RUN mkdir -p /opt/workspace
WORKDIR /opt/workspace

RUN adduser testuser --disabled-login
USER testuser
