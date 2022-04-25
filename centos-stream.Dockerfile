ARG CENTOS_VERSION
FROM quay.io/centos/centos:stream$CENTOS_VERSION

ENV \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # listen on port 5000 by default
    DOTNET_URLS=http://+:5000

ARG DOTNET_VERSION
RUN dnf install -y aspnetcore-runtime-$DOTNET_VERSION \
    && dotnet --info
