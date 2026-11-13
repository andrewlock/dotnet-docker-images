ARG CENTOS_VERSION

# Build the smoke test against the .NET version being installed (always using the latest SDK)
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:11.0 AS smoke-test
ARG DOTNET_VERSION
WORKDIR /src
COPY smoke-test/ .
RUN dotnet publish -c Release -o /out -nologo -p:SmokeTestTfm=netcoreapp$(echo "$DOTNET_VERSION" | cut -d. -f1,2)

FROM quay.io/centos/centos:stream${CENTOS_VERSION}

ENV \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # listen on port 5000 by default
    DOTNET_URLS=http://+:5000 \
    # Disable telemetry (also covers dotnetup itself)
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    # Fixed install location, readable by all users. Also lets apphost executables find the runtime.
    DOTNET_ROOT=/opt/dotnet

# CentOS Stream 8 is EOL, so its packages have moved to the vault
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo

ARG DOTNET_VERSION
RUN dnf install -y ca-certificates glibc krb5-libs libgcc libicu libstdc++ openssl-libs tzdata zlib \
    && dnf clean all \
    && curl -fsSL https://aka.ms/dotnetup/get-dotnetup.sh | bash -s -- --install-dir /tmp/dotnetup \
    && /tmp/dotnetup/dotnetup runtime install aspnetcore@$DOTNET_VERSION \
        --install-path $DOTNET_ROOT --untracked --no-progress --interactive false \
    && rm -rf /tmp/dotnetup /root/.local/share/dotnetup /root/.dotnetup \
    && ln -s $DOTNET_ROOT/dotnet /usr/bin/dotnet \
    && dotnet --info

# Check the native dependencies (ICU, OpenSSL, zlib) actually load. The smoke test isn't left in the image.
RUN --mount=type=bind,from=smoke-test,source=/out,target=/smoke-test \
    dotnet /smoke-test/SmokeTest.dll
