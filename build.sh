#!/usr/bin/env bash
set -euo pipefail

docker_image_exists() {
  local repo="$1"
  local tag="$2"
  local max_retries=3
  local delay=2
  local attempt=0
  local image="${repo}:${tag}"

  while (( attempt < max_retries )); do
    output=$(docker buildx imagetools inspect "$image" 2>&1)
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
      return 0  # Image exists
    fi

    if echo "$output" | grep -qiE "not[[:space:]]+found|no[[:space:]]+such[[:space:]]+manifest|manifest unknown"; then
      return 1  # Image does not exist
    fi

    # Transient error — retry
    ((attempt++))
    if (( attempt < max_retries )); then
      echo "docker_image_exists: transient error (attempt $attempt): $output" >&2
      sleep "$delay"
      delay=$((delay * 2))
    else
      echo "docker_image_exists: failed after $max_retries attempts: $output" >&2
      return 1
    fi
  done
}


echo "Building Debian images"
for i in "trixie 8.0.18 8.0" "trixie 9.0.7 9.0" ; do 
    a=( $i )
    debianVersion="${a[0]}";
    dotnetVersion="${a[1]}";
    dotnetVersionShort="${a[2]}";

    image="andrewlock/dotnet-debian"
    tag=$debianVersion-$dotnetVersionShort
    if docker_image_exists $image $tag; then
        echo "${image}:${tag} exists, skipping"
        continue
    fi
    
    echo "building debian:$debianVersion-slim for .NET $dotnetVersion x64"
    docker buildx build \
        --build-arg DEBIAN_VERSION=$debianVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./debian.Dockerfile \
        -t $image \
        --platform linux/amd64  \
        --provenance false \
        --metadata-file metadata.x64.json \
        --output push-by-digest=true,type=image,push=true \
        .

    digest_x64=$(jq -r '.["containerimage.digest"]' metadata.x64.json)
    echo "Built image digest: ${digest_x64}"

    echo "building debian:$debianVersion-slim for .NET $dotnetVersion arm64"
    docker buildx build \
        --build-arg DEBIAN_VERSION=$debianVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./debian.arm64.Dockerfile \
        -t $image \
        --platform linux/arm64  \
        --provenance false \
        --metadata-file metadata.arm64.json \
        --output push-by-digest=true,type=image,push=true \
        .

    digest_arm64=$(jq -r '.["containerimage.digest"]' metadata.arm64.json)
    echo "Built image digest: ${digest_arm64}"

    echo "Creating $image:$tag"
    docker manifest create $image:$tag \
        $image@${digest_x64} \
        $image@${digest_arm64}

    docker manifest push $image:$tag

done;

echo "Building Ubuntu images"
for i in "25.04 8.0" "25.04 9.0" ; do 
    a=( $i )
    ubuntuVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    image="andrewlock/dotnet-ubuntu"
    tag=$ubuntuVersion-$dotnetVersion
    if docker_image_exists $image $tag; then
        echo "${image}:${tag} exists, skipping"
        continue
    fi
    
    echo "building ubuntu:$ubuntuVersion for .NET $dotnetVersion"
    docker buildx build \
        --build-arg UBUNTU_VERSION=$ubuntuVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./ubuntu.Dockerfile \
        -t $image:$tag \
        --platform linux/arm64,linux/amd64  \
        --push .

done;

echo "Building Fedora images"
for i in "40 9.0" "37 8.0" "36 8.0" "36 7.0" "35 7.0" "35 5.0" "35 3.1" "34 6.0" "34 5.0" "34 3.1" "33 5.0" "33 3.1" "29 3.1" "29 2.1" ; do 
    a=( $i )
    fedoraVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    image="andrewlock/dotnet-fedora"
    tag=$fedoraVersion-$dotnetVersion
    if docker_image_exists $image $tag; then
        echo "${image}:${tag} exists, skipping"
        continue
    fi

    echo "Building ${image}:${tag}..."

    docker build \
        --build-arg FEDORA_VERSION=$fedoraVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./fedora.Dockerfile \
        -t $image:$tag \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push $image:$tag
    else
        echo "Skipping push"
    fi

done;

echo "Building Fedora Arm64 images"
for i in "40 9.0" "37 8.0" "36 8.0" "35 7.0" "35 5.0" "34 6.0" "33 3.1" ; do 
    a=( $i )
    fedoraVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    image="andrewlock/dotnet-fedora-arm64"
    tag=$fedoraVersion-$dotnetVersion
    if docker_image_exists $image $tag; then
        echo "${image}:${tag} exists, skipping"
        continue
    fi
    echo "Building ${image}:${tag}..."
    
    docker buildx build \
        --build-arg FEDORA_VERSION=$fedoraVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./fedora.arm64.Dockerfile \
        -t $image:$tag \
        --platform linux/arm64 \
        --push .

done;

echo "Building CentOS 7 images"
for i in "7 2.1" "7 3.1" "7 5.0" "7 6.0" "7 7.0"; do 
    a=( $i )
    centosVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    image="andrewlock/dotnet-centos"
    tag=$centosVersion-$dotnetVersion
    if docker_image_exists $image $tag; then
        echo "${image}:${tag} exists, skipping"
        continue
    fi
    echo "Building ${image}:${tag}..."

    docker build \
        --build-arg CENTOS_VERSION=$centosVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./centos.Dockerfile \
        -t $image:$tag \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push $image:$tag
    else
        echo "Skipping push"
    fi

done;

echo "Building RHEL 8+9 images"
for i in "8 9.0" "9 9.0" "8 3.1" "8 5.0" "8 6.0" "8 7.0"; do 
    a=( $i )
    rhelVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    image="andrewlock/dotnet-rhel"
    tag=$rhelVersion-$dotnetVersion
    if docker_image_exists $image $tag; then
        echo "${image}:${tag} exists, skipping"
        continue
    fi
    echo "Building ${image}:${tag}..."

    docker build \
        --build-arg RHEL_VERSION=$rhelVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./rhel.Dockerfile \
        -t $image:$tag \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push $image:$tag
    else
        echo "Skipping push"
    fi

done;

echo "Building CentOS Stream images"
for i in "9 9.0" "8 3.1" "8 5.0" "8 6.0" "9 6.0" "8 7.0" "9 7.0"; do 
    a=( $i )
    centosVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    image="andrewlock/dotnet-centos-stream"
    tag=$centosVersion-$dotnetVersion
    if docker_image_exists $image $tag; then
        echo "${image}:${tag} exists, skipping"
        continue
    fi
    echo "Building ${image}:${tag}..."

    docker build \
        --build-arg CENTOS_VERSION=$centosVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./centos-stream.Dockerfile \
        -t $image:$tag \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push $image:$tag
    else
        echo "Skipping push"
    fi

done;

echo "Building Open Suse images"
for i in  "15 9.0" "15 2.1" "15 3.1" "15 5.0" "15 6.0" "15 7.0"; do 
    a=( $i )
    opensuse="${a[0]}";
    dotnetVersion="${a[1]}";

    image="andrewlock/dotnet-opensuse"
    tag=$opensuse-$dotnetVersion
    if docker_image_exists $image $tag; then
        echo "${image}:${tag} exists, skipping"
        continue
    fi
    echo "Building ${image}:${tag}..."

    docker build \
        --build-arg OPENSUSE_VERSION=$opensuse \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./opensuse.Dockerfile \
        -t $image:$tag \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push $image:$tag
    else
        echo "Skipping push"
    fi

done;