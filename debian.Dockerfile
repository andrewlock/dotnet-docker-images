ARG DEBIAN_VERSION

# Build the smoke test against the .NET version being installed (always using the latest SDK)
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:11.0 AS smoke-test
ARG DOTNET_VERSION
WORKDIR /src
COPY smoke-test/ .
RUN dotnet publish -c Release -o /out -nologo -p:SmokeTestTfm=netcoreapp$(echo "$DOTNET_VERSION" | cut -d. -f1,2)

FROM debian:${DEBIAN_VERSION}-slim

ENV \
    # UID of the non-root user 'app'
    APP_UID=1654 \
    # Configure web servers to bind to port 8080 when present
    ASPNETCORE_HTTP_PORTS=8080 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # Disable telemetry (also covers dotnetup itself)
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    # Fixed install location, readable by all users. Also lets apphost executables find the runtime.
    DOTNET_ROOT=/opt/dotnet

# Create a non-root user and group
RUN groupadd \
        --gid=$APP_UID \
        app \
    && useradd --no-log-init \
        --uid=$APP_UID \
        --gid=$APP_UID \
        --create-home \
        app

ARG DOTNET_VERSION
# The ICU package name includes its version (e.g. libicu76), so pick the newest available
RUN apt-get update \
    && libicu=$(apt-cache pkgnames libicu | grep -E '^libicu[0-9]+$' | sort -V | tail -1) \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl libc6 libgcc-s1 libgssapi-krb5-2 $libicu libssl3t64 libstdc++6 tzdata zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://aka.ms/dotnetup/get-dotnetup.sh | bash -s -- --install-dir /tmp/dotnetup \
    && /tmp/dotnetup/dotnetup runtime install aspnetcore@$DOTNET_VERSION \
        --install-path $DOTNET_ROOT --untracked --no-progress --interactive false \
    && rm -rf /tmp/dotnetup /root/.local/share/dotnetup /root/.dotnetup \
    && ln -s $DOTNET_ROOT/dotnet /usr/bin/dotnet \
    && dotnet --info

# Check the native dependencies (ICU, OpenSSL, zlib) actually load. The smoke test isn't left in the image.
RUN --mount=type=bind,from=smoke-test,source=/out,target=/smoke-test \
    dotnet /smoke-test/SmokeTest.dll
