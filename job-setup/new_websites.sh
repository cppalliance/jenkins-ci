#!/bin/bash

set -e

: '
A script to configure the website components of doc previews.

Initial Setup:
Add credentials files:
~/.config/cloudflare_credentials_cpp_al
~/.config/cloudflare_credentials_cppalliance_org
Format of the contents of each file:
#!/bin/bash
export dns_cloudflare_zoneid="___"
export dns_cloudflare_email="___"
export dns_cloudflare_api_token="__"

website-templates/base_pr_template and base_website_template are required files
but should already be present in the website-templates directory here.
'

scriptname="new_websites.sh"

# READ IN COMMAND-LINE OPTIONS
TEMP=$(getopt -o h:: --long help::,skip-prs::,skip-branches:: -- "$@")
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -h|--help)
            helpmessage="""
usage: $scriptname [-h] [--skip-prs] [--skip-branches] [library_name]

Set up the website components of doc previews.
Creates nginx vhosts. Adds DNS entries in cloudflare. Requests Let's Encrypt certificates.

optional arguments:
  -h, --help            Show this help message and exit
  --skip-prs            Skip pull requests, only preview master/develop branches
  --skip-branches       Skip the master/develop branches, only preview pull requests
standard arguments:
  library_name          The name of the library. Currently, both boostorg and cppalliance
                        are hosted the same way so the organization name should be omitted.
"""

            echo ""
            echo "$helpmessage" ;
            echo ""
            exit 0
            ;;
        --skip-prs)
            skip_pr_option="yes" ; shift 2 ;;
        --skip-branches)
            skip_branch_option="yes" ; shift 2 ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

reponame=$1

if [ -z "$reponame" ]; then
    echo "Please set reponame value. Exiting."
    exit 1
fi

if [[ "$reponame" =~ / ]] ; then
    echo "The reponame should be a basic repository without the organization included."
    exit 1
fi

dnsreponame=${reponame//_/-}

if [ ! "$reponame" = "$dnsreponame" ]; then
    echo "reponame is $reponame"
    echo "dnsreponame is $dnsreponame"
fi

dns_cloudflare_email=""
dns_cloudflare_api_token=""
dns_cloudflare_zoneid=""

function master_develop_sites {

    echo "Step 1: master develop previews. DNS."

    branches="develop master"

    # shellcheck source=/dev/null
    . ~/.config/cloudflare_credentials_cpp_al

    for branch in $branches; do

        dns_cname_record="${branch}.${dnsreponame}.cpp.al"
        echo "dns_cname_record is $dns_cname_record"

        sleep 10

        curl --request POST \
          --url "https://api.cloudflare.com/client/v4/zones/$dns_cloudflare_zoneid/dns_records" \
          --header "Content-Type: application/json" \
          --header "X-Auth-Email: $dns_cloudflare_email" \
          --header "Authorization: Bearer $dns_cloudflare_api_token" \
          --data '{
          "content": "jenkins.cppalliance.org.",
          "name": "'"${dns_cname_record}"'",
          "type": "CNAME",
          "proxied": false
        }'

        sleep 10
    done

    echo " "
    echo "Step 2: Create nginx sites for master develop previews"
    echo " "

    for branch in $branches; do

        website="${branch}.${dnsreponame}.cpp.al"
        echo "website is $website"

        if [ -f "/etc/nginx/sites-enabled/$website" ]; then
            echo "The file /etc/nginx/sites-enabled/$website already exists. Skipping to the next site."
            continue
        fi

        sleep 10

        cp -i website-templates/base_website_template "/etc/nginx/sites-available/$website"
        sed -i "s/_website_name_/$website/" "/etc/nginx/sites-available/$website"
        ln -s "/etc/nginx/sites-available/$website" "/etc/nginx/sites-enabled/$website"
        systemctl restart nginx

        sleep 2

        echo " "
        echo "STEP 3: Requesting cert"
        echo " "

        certbot certonly --webroot-path /var/www/letsencrypt --webroot -d "$website"

        echo " "
        echo "STEP 3 continued: MODIFYING RENEWAL FILE"
        echo " "

        renewalfile=/etc/letsencrypt/renewal/${website}.conf
        if ! grep try-reload-or-restart "$renewalfile" ; then
           sed -i 's/\[renewalparams\]/[renewalparams]\nrenew_hook = systemctl try-reload-or-restart nginx/' "$renewalfile"
        fi

        echo " "
        echo "STEP 4: Shift nginx site to use the new cert"
        echo " "

        sed -i "s/develop.json.cpp.al/$website/" "/etc/nginx/sites-available/$website"
    done

    systemctl restart nginx

}

function pr_sites {

    echo "Step 1: pull request previews. DNS."

    # shellcheck source=/dev/null
    . ~/.config/cloudflare_credentials_cppalliance_org

    dns_cname_record="*.${dnsreponame}.prtest3.cppalliance.org"
    echo "dns_cname_record is $dns_cname_record"

    sleep 10

    curl --request POST \
      --url "https://api.cloudflare.com/client/v4/zones/$dns_cloudflare_zoneid/dns_records" \
      --header "Content-Type: application/json" \
      --header "X-Auth-Email: $dns_cloudflare_email" \
      --header "Authorization: Bearer $dns_cloudflare_api_token" \
      --data '{
      "content": "jenkins.cppalliance.org.",
      "name": "'"${dns_cname_record}"'",
      "type": "CNAME",
      "proxied": false
    }'

    sleep 10

    echo " "
    echo "Step 2: Create nginx sites for PR previews"
    echo " "

    # for statement so that continue will work
    # shellcheck disable=SC2034,SC2043
    for x in 1; do

        website="${dnsreponame}.prtest3.cppalliance.org"
        echo "website is $website"

        if [ -f "/etc/nginx/sites-enabled/$website" ]; then
            echo "The file /etc/nginx/sites-enabled/$website already exists. Skipping to the next site."
            continue
        fi

        sleep 10

        cp -i website-templates/base_pr_template "/etc/nginx/sites-available/$website"
        sed -i "s/_website_name_/$dns_cname_record/" "/etc/nginx/sites-available/$website"
        ln -s "/etc/nginx/sites-available/$website" "/etc/nginx/sites-enabled/$website"
        systemctl daemon-reload
        systemctl restart nginx

        sleep 10

        echo " "
        echo "Step 3: Requesting certs for PR previews"
        echo " "

        certbot certonly --dns-cloudflare --dns-cloudflare-propagation-seconds 20 --dns-cloudflare-credentials /etc/letsencrypt/.secret -d "$dns_cname_record"

        echo " "
        echo "STEP 3 continued: MODIFYING RENEWAL FILE"
        echo " "

        renewalfile=/etc/letsencrypt/renewal/${website}.conf
        if ! grep try-reload-or-restart "$renewalfile" ; then
           sed -i 's/\[renewalparams\]/[renewalparams]\nrenew_hook = systemctl try-reload-or-restart nginx/' "$renewalfile"
        fi

        echo " "
        echo "STEP 4: Shift nginx site to use the new cert"
        echo " "

        sed -i "s/develop.json.cpp.al/$website/" "/etc/nginx/sites-available/$website"

    done
    systemctl daemon-reload
    systemctl restart nginx

}

if [ ! "$skip_branch_option" = "yes" ]; then
    master_develop_sites
fi

if [ ! "$skip_pr_option" = "yes" ]; then
    pr_sites
fi
