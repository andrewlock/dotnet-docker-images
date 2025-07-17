# Based on https://github.com/dotnet/dotnet-docker/blob/22c8e77e62db8d53aca5a95c67769b249cc2a835/src/runtime-deps/10.0/trixie-slim/amd64/Dockerfile
ARG DEBIAN_VERSION
ARG TARGETARCH

# Installer image
FROM arm64v8/buildpack-deps:${DEBIAN_VERSION}-curl AS installer

# Retrieve .NET Runtime
ARG DOTNET_VERSION
RUN dotnet_version=${DOTNET_VERSION} \
    && curl --fail --show-error --location \
        --remote-name https://builds.dotnet.microsoft.com/dotnet/Runtime/$dotnet_version/dotnet-runtime-$dotnet_version-linux-arm64.tar.gz \
        --remote-name https://builds.dotnet.microsoft.com/dotnet/checksums/$dotnet_version-sha.txt \
    && sed -i 's/\r$//' $dotnet_version-sha.txt \
    && sha512sum -c $dotnet_version-sha.txt --ignore-missing \
    && mkdir --parents /dotnet \
    && tar --gzip --extract --no-same-owner --file dotnet-runtime-$dotnet_version-linux-arm64.tar.gz --directory /dotnet \
    && rm \
        dotnet-runtime-$dotnet_version-linux-arm64.tar.gz \
        $dotnet_version-sha.txt

# Retrieve ASP.NET Core
RUN aspnetcore_version=${DOTNET_VERSION} \
    && curl --fail --show-error --location \
        --remote-name https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/$aspnetcore_version/aspnetcore-runtime-$aspnetcore_version-linux-arm64.tar.gz \
        --remote-name https://builds.dotnet.microsoft.com/dotnet/checksums/$aspnetcore_version-sha.txt \
    && sed -i 's/\r$//' $aspnetcore_version-sha.txt \
    && sha512sum -c $aspnetcore_version-sha.txt --ignore-missing \
    && mkdir --parents /dotnet \
    && tar --gzip --extract --no-same-owner --file aspnetcore-runtime-$aspnetcore_version-linux-arm64.tar.gz --directory /dotnet ./shared/Microsoft.AspNetCore.App \
    && rm \
        aspnetcore-runtime-$aspnetcore_version-linux-arm64.tar.gz \
        $aspnetcore_version-sha.txt

FROM debian:${DEBIAN_VERSION}-slim

ENV \
    # UID of the non-root user 'app'
    APP_UID=1654 \
    # Configure web servers to bind to port 8080 when present
    ASPNETCORE_HTTP_PORTS=8080 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        \
        # .NET dependencies
        libc6 \
        libgcc-s1 \
        libicu76 \
        libssl3t64 \
        libstdc++6 \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user and group
RUN groupadd \
        --gid=$APP_UID \
        app \
    && useradd --no-log-init \
        --uid=$APP_UID \
        --gid=$APP_UID \
        --create-home \
        app

ENV \
    DOTNET_NOLOGO=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip

# ASP.NET Core version
ARG DOTNET_VERSION
ENV ASPNET_VERSION=${DOTNET_VERSION}
ENV DOTNET_VERSION=${DOTNET_VERSION}

COPY --from=installer ["/dotnet", "/usr/share/dotnet"]

RUN ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet