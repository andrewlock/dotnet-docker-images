ARG FEDORA_VERSION
FROM fedora:$FEDORA_VERSION

ENV \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip

ARG FEDORA_VERSION
ARG DOTNET_VERSION
RUN yum install wget -y \
    && (rpm --import https://packages.microsoft.com/keys/microsoft.asc || echo 'Skipping key import')  \
    && (wget -O /etc/yum.repos.d/microsoft-prod.repo https://packages.microsoft.com/config/fedora/$FEDORA_VERSION/prod.repo || echo 'Skipping add repo') \
    && dnf install -y aspnetcore-runtime-$DOTNET_VERSION \
    && dotnet --info \
    && yum remove -y wget
