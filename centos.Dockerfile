# Build the smoke test against the .NET version being installed (always using the latest SDK)
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:11.0 AS smoke-test
ARG DOTNET_VERSION
WORKDIR /src
COPY smoke-test/ .
RUN dotnet publish -c Release -o /out -nologo -p:SmokeTestTfm=netcoreapp$(echo "$DOTNET_VERSION" | cut -d. -f1,2)

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

# Check the native dependencies (ICU, OpenSSL, zlib) actually load. The smoke test isn't left in the image.
RUN --mount=type=bind,from=smoke-test,source=/out,target=/smoke-test \
    dotnet /smoke-test/SmokeTest.dll
