#!/bin/bash

# Untested. And shouldn't this move to the nagios playbooks.

echo "*/5 * * * * /usr/lib/nagios/plugins/check_jenkins_queue > /dev/null 2>&1" >> /var/spool/cron/crontabs/root
