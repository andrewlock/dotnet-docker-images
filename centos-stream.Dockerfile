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

ARG CENTOS_VERSION
ARG DOTNET_VERSION

RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
# Work around problem where CentOS 8 doesn't have the latest version of .NET
RUN if [ "$CENTOS_VERSION" = "8" ] ; then rpm -Uvh https://packages.microsoft.com/config/centos/$CENTOS_VERSION/packages-microsoft-prod.rpm \
    && echo 'priority=50' | tee -a /etc/yum.repos.d/microsoft-prod.repo; fi; \
    dnf install -y aspnetcore-runtime-$DOTNET_VERSION \
    && dotnet --info
