ARG FEDORA_VERSION
FROM fedora:$FEDORA_VERSION

ENV \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # This is the default install location for dotnetup
    DOTNET_PATH="/root/.local/share/dotnetup/dotnet"

ENV PATH="${DOTNET_PATH}:${PATH}"

ARG DOTNET_VERSION
RUN dnf install -y glibc libgcc ca-certificates openssl-libs libstdc++ libicu tzdata krb5-libs zlib \
  && (curl -fsSL https://aka.ms/dotnetup/get-dotnetup.sh | sh) \
  && /root/.dotnetup/dotnetup runtime install aspnetcore@$DOTNET_VERSION --set-default-install --no-progress --interactive false \
  && dotnet --info
