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
