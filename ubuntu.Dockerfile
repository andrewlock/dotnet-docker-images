# Declare ARG before using it in FROM
ARG UBUNTU_VERSION
FROM ubuntu:${UBUNTU_VERSION}

ARG UBUNTU_VERSION
ARG DOTNET_VERSION

ENV \
    DOTNET_NOLOGO=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip

RUN apt-get update \
 && apt-get install -y aspnetcore-runtime-$DOTNET_VERSION
