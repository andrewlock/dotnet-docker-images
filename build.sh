#!/usr/bin/env bash
set -euo pipefail

echo "Building Fedora images"
for i in "40 9.0" "35 7.0" "35 5.0" "35 3.1" "34 6.0" "34 5.0" "34 3.1" "33 5.0" "33 3.1" "29 3.1" "29 2.1" ; do 
    a=( $i )
    fedoraVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    docker build \
        --build-arg FEDORA_VERSION=$fedoraVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./fedora.Dockerfile \
        -t andrewlock/dotnet-fedora:$fedoraVersion-$dotnetVersion \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push andrewlock/dotnet-fedora:$fedoraVersion-$dotnetVersion
    else
        echo "Skipping push"
    fi

done;

echo "Building Fedora Arm64 images"
for i in "40 9.0" "35 7.0" "35 5.0" "34 6.0" "33 3.1" ; do 
    a=( $i )
    fedoraVersion="${a[0]}";
    dotnetVersion="${a[1]}";
    
    docker buildx build \
        --build-arg FEDORA_VERSION=$fedoraVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./fedora.arm64.Dockerfile \
        -t andrewlock/dotnet-fedora-arm64:$fedoraVersion-$dotnetVersion \
        --platform linux/arm64 \
        --push .

done;

echo "Building CentOS 7 images"
for i in "7 2.1" "7 3.1" "7 5.0" "7 6.0" "7 7.0"; do 
    a=( $i )
    centosVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    docker build \
        --build-arg CENTOS_VERSION=$centosVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./centos.Dockerfile \
        -t andrewlock/dotnet-centos:$centosVersion-$dotnetVersion \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push andrewlock/dotnet-centos:$centosVersion-$dotnetVersion
    else
        echo "Skipping push"
    fi

done;

echo "Building RHEL 8+9 images"
for i in "8 9.0" "9 9.0" "8 3.1" "8 5.0" "8 6.0" "8 7.0"; do 
    a=( $i )
    rhelVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    docker build \
        --build-arg RHEL_VERSION=$rhelVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./rhel.Dockerfile \
        -t andrewlock/dotnet-rhel:$rhelVersion-$dotnetVersion \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push andrewlock/dotnet-rhel:$rhelVersion-$dotnetVersion
    else
        echo "Skipping push"
    fi

done;

echo "Building CentOS Stream images"
for i in "9 9.0" "8 3.1" "8 5.0" "8 6.0" "9 6.0" "8 7.0" "9 7.0"; do 
    a=( $i )
    centosVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    docker build \
        --build-arg CENTOS_VERSION=$centosVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./centos-stream.Dockerfile \
        -t andrewlock/dotnet-centos-stream:$centosVersion-$dotnetVersion \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push andrewlock/dotnet-centos-stream:$centosVersion-$dotnetVersion
    else
        echo "Skipping push"
    fi

done;

echo "Building Open Suse images"
for i in  "15 9.0" "15 2.1" "15 3.1" "15 5.0" "15 6.0" "15 7.0"; do 
    a=( $i )
    opensuse="${a[0]}";
    dotnetVersion="${a[1]}";

    docker build \
        --build-arg OPENSUSE_VERSION=$opensuse \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./opensuse.Dockerfile \
        -t andrewlock/dotnet-opensuse:$opensuse-$dotnetVersion \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push andrewlock/dotnet-opensuse:$opensuse-$dotnetVersion
    else
        echo "Skipping push"
    fi

done;