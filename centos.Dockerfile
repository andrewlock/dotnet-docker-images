FROM centos:7

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
# Add Microsoft package repository and install ASP.NET Core
RUN rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm \
    && sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo \
    && yum install -y aspnetcore-runtime-$DOTNET_VERSION \
    && dotnet --info
