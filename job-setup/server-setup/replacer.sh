#!/bin/bash

set -xe

string1="<daysToKeep>-1</daysToKeep>"
string2="<daysToKeep>14</daysToKeep>"

find ./ -maxdepth 2 -type f -name "config.xml" -exec sed -i "s~$string1~$string2~g" {} \;
