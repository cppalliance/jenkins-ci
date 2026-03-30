#!/bin/bash

set -xe

        . ~/.config/jenkins_credentials
        java -jar /usr/bin/jenkins-cli.jar -s http://localhost:8080 -auth $JENKINS_USER:$JENKINS_PASSWORD reload-configuration

