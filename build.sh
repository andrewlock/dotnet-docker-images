#!/usr/bin/env bash
set -euo pipefail

echo "Building Fedora images"
for i in "35 5.0" "35 3.1" "34 6.0" "34 5.0" "34 3.1" "33 5.0" "33 3.1" "29 3.1" "29 2.1"; do 
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

echo "Building CentOS 7 images"
for i in "7 2.1" "7 3.1" "7 5.0" "7 6.0"; do 
    a=( $i )
    centosVersion="${a[0]}";
    dotnetVersion="${a[1]}";

    docker build \
        --build-arg CENTOS_VERSION=$centosVersion \
        --build-arg DOTNET_VERSION=$dotnetVersion \
        -f ./centos7.Dockerfile \
        -t andrewlock/dotnet-centos:$centosVersion-$dotnetVersion \
        .

    if [[ "${1-''}" == "push" ]]
    then
        docker push andrewlock/dotnet-centos:$centosVersion-$dotnetVersion
    else
        echo "Skipping push"
    fi

done;