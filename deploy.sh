#!/bin/bash

# extract out the current project version, so that we can use and append it to the docker build
bookshop_demo_version=$(echo `mvn help:evaluate -Dexpression=project.version -q -DforceStdout` | sed 's/-SNAPSHOT//')
if [ -z "$bookshop_demo_version" ]; then
    # default it if version is empty
    bookshop_demo_version="latest"
fi

# build the "keycloak-bookshop-demo/checkout-react"
currentDir=`pwd`
checkoutReactSourceDir="./checkout-react"
checkoutReactDistDir="dist"
if [ -d "$checkoutReactSourceDir/$checkoutReactDistDir" ]; then
    rm -rf "$checkoutReactSourceDir/$checkoutReactDistDir"
fi
checkoutReactNodeModulesDir="node_modules"
if [ -d "$checkoutReactSourceDir/$checkoutReactNodeModulesDir" ]; then
    rm -rf "$checkoutReactSourceDir/$checkoutReactNodeModulesDir"
    cd "$checkoutReactSourceDir"
    npm prune
    rcNpmPrune=$?
    if [ "$rcNpmPrune" != "0" ]; then
        echo "ERROR : NPM prune ENCOUNTERED FAILURE EXIT CODE ['$rcNpmPrune']"
        cd "$currentDir"
        exit $rcNpmPrune
    fi
    cd "$currentDir"
fi
cd "$checkoutReactSourceDir"
npm install
rcNpmInstall=$?
if [ "$rcNpmInstall" != "0" ]; then
    echo "ERROR : NPM install ENCOUNTERED FAILURE EXIT CODE ['$rcNpmInstall']"
    cd "$currentDir"
    exit $rcNpmInstall
fi
npm run build
rcNpmRunBuild=$?
if [ "$rcNpmRunBuild" != "0" ]; then
    echo "ERROR : NPM run build ENCOUNTERED FAILURE EXIT CODE ['$rcNpmRunBuild']"
    cd "$currentDir"
    exit $rcNpmRunBuild
fi
if [ ! -d "$checkoutReactDistDir" ]; then
    echo "ERROR : NPM run build OK BUT MISSING DIST DIRECTORY ['$checkoutReactDistDir']"
    cd "$currentDir"
    exit 1
fi
cd "$currentDir"

# build the "keycloak-bookshop-demo"
mvn clean package
rcMvnCleanPackage=$?
if [ "$rcMvnCleanPackage" != "0" ]; then
    echo "ERROR : Maven clean package ENCOUNTERED FAILURE EXIT CODE ['$rcMvnCleanPackage']"
    exit $rcMvnCleanPackage
fi

docker build -t dasniko/bookshop:$bookshop_demo_version -f docker/Dockerfile .
rcDockerBuild=$?
if [ "$rcDockerBuild" != "0" ]; then
    echo "ERROR : Docker build image ENCOUNTERED FAILURE EXIT CODE ['$rcDockerBuild']"
    exit $rcDockerBuild
fi

#docker buildx build --pull --platform linux/amd64,linux/arm64 -t dasniko/bookshop -f docker/Dockerfile . --push
docker image prune -f
rcDockerImagePrune=$?
if [ "$rcDockerImagePrune" != "0" ]; then
    echo "ERROR : Docker image prune ENCOUNTERED FAILURE EXIT CODE ['$rcDockerImagePrune']"
    exit $rcDockerImagePrune
fi
