ARG BASE_TAG
FROM docker/sandbox-templates:${BASE_TAG}

# Switch to root to run package manager installs (.NET dependencies)
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    libc6 \
    libgcc-s1 \
    libgssapi-krb5-2 \
    libicu76 \
    libssl3t64 \
    libstdc++6 \
    tzdata \
    zlib1g

ENV \
    # Do not show first run text
    DOTNET_NOLOGO=1 \
    # Disable telemetry to reduce overhead
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip

# Most tools should be installed at user-level, using agent user
USER agent

# Install ASP.NET Core runtimes using install script
# There is no arm64 runtime available for .NET Core 2.1, so just install the .NET Core runtime in that case
RUN if [ "$(uname -m)" = "x86_64" ]; \
    then export NETCORERUNTIME2_1=aspnetcore; \
    else export NETCORERUNTIME2_1=dotnet; \
    fi \
    && curl -sSL https://dot.net/v1/dotnet-install.sh --output dotnet-install.sh  \
    && chmod +x ./dotnet-install.sh \
    && ./dotnet-install.sh --channel 10.0 --install-dir /home/agent/.dotnet \
    && ./dotnet-install.sh --runtime $NETCORERUNTIME2_1 --channel 2.1 --install-dir /home/agent/.dotnet --no-path \
    && ./dotnet-install.sh --runtime aspnetcore --channel 3.0 --install-dir /home/agent/.dotnet --no-path \
    && ./dotnet-install.sh --runtime aspnetcore --channel 3.1 --install-dir /home/agent/.dotnet --no-path \
    && ./dotnet-install.sh --runtime aspnetcore --channel 5.0 --install-dir /home/agent/.dotnet --no-path \
    && ./dotnet-install.sh --runtime aspnetcore --channel 6.0 --install-dir /home/agent/.dotnet --no-path \
    && ./dotnet-install.sh --runtime aspnetcore --channel 7.0 --install-dir /home/agent/.dotnet --no-path \
    && ./dotnet-install.sh --runtime aspnetcore --channel 8.0 --install-dir /home/agent/.dotnet --no-path \
    && ./dotnet-install.sh --runtime aspnetcore --channel 9.0 --install-dir /home/agent/.dotnet --no-path \
    && rm ./dotnet-install.sh \
    && sudo ln -s /home/agent/.dotnet/dotnet /usr/bin/dotnet \
# Trigger first run experience by running arbitrary cmd
    && dotnet help

ENV DOTNET_ROOT=/home/agent/.dotnet \
    PATH=$PATH:/home/agent/.dotnet:/home/agent/.dotnet/tools