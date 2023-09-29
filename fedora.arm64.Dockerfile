ARG FEDORA_VERSION
FROM fedora:$FEDORA_VERSION

ENV \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip

ARG DOTNET_VERSION
RUN dnf install -y findutils \
    && curl -sL -o dotnet-install.sh https://dot.net/v1/dotnet-install.sh  \
    && chmod +x ./dotnet-install.sh \
    && ./dotnet-install.sh --channel $DOTNET_VERSION --runtime aspnetcore \
    && rm ./dotnet-install.sh