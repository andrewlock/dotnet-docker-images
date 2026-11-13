ARG DISTRO_VERSION

# Build the smoke test against the .NET version being installed (always using the latest SDK)
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:11.0 AS smoke-test
ARG DOTNET_VERSION
WORKDIR /src
COPY smoke-test/ .
RUN dotnet publish -c Release -o /out -nologo -p:SmokeTestTfm=netcoreapp$(echo "$DOTNET_VERSION" | cut -d. -f1,2)

FROM amazonlinux:${DISTRO_VERSION}

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
ARG DOTNET_VERSION
# The default OpenSSL on Amazon Linux 2 is 1.0.2, which dotnetup (and .NET 8+) don't support
RUN yum install -y ca-certificates glibc krb5-libs libgcc libicu libstdc++ openssl11-libs tzdata zlib \
    && yum clean all \
    && curl -fsSL https://aka.ms/dotnetup/get-dotnetup.sh | bash -s -- --install-dir /tmp/dotnetup \
    && /tmp/dotnetup/dotnetup runtime install aspnetcore@$DOTNET_VERSION \
        --install-path $DOTNET_ROOT --untracked --no-progress --interactive false \
    && rm -rf /tmp/dotnetup /root/.local/share/dotnetup /root/.dotnetup \
    && ln -s $DOTNET_ROOT/dotnet /usr/bin/dotnet \
    && dotnet --info

# Check the native dependencies (ICU, OpenSSL, zlib) actually load. The smoke test isn't left in the image.
RUN --mount=type=bind,from=smoke-test,source=/out,target=/smoke-test \
    dotnet /smoke-test/SmokeTest.dll
