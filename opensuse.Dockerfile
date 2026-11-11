ARG OPENSUSE_VERSION
FROM opensuse/leap:$OPENSUSE_VERSION

ENV \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # listen on port 5000 by default
    DOTNET_URLS=http://+:5000 \
    # This is the default install location for dotnetup
    DOTNET_PATH="/root/.local/share/dotnetup/dotnet"

ENV PATH="${DOTNET_PATH}:${PATH}"

ARG DOTNET_VERSION
# add the Microsoft package signing key to your list of trusted keys and add the Microsoft package repository
# Earlier versions of .NET need to use an earlier version of zypper
RUN if [ "$DOTNET_VERSION" == "2.1" ] || [ "$DOTNET_VERSION" == "3.1" ]; \
      then zypper install -y libicu69-69.1-7.3.2; \
      else zypper install -y libicu; fi\
    && zypper install -y ca-certificates glibc krb5 libgcc_s1 libicu libopenssl3 libstdc++6 timezone zlib  \
    && (curl -fsSL https://aka.ms/dotnetup/get-dotnetup.sh | sh) \
    && /root/.dotnetup/dotnetup runtime install aspnetcore@$DOTNET_VERSION --set-default-install --no-progress --interactive false \
    && dotnet --info
