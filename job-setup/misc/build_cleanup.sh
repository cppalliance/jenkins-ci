#!/bin/bash

set -xe

END=10
for i in $(seq 1 $END); do
  echo $i;
done

cd /var/lib/jenkins/jobs/jsondocs/builds
END=1670
for i in $(seq 1 $END); do
  echo $i;
  rm -rf $i || true
done

