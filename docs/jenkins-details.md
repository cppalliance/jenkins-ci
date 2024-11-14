## Jenkins System and Job Information
  
For a brief summary of how Jenkins works, please refer back to [this page](jenkins-summary.md).  
 
- [Installation](#installation)
- [Job Information](#jobs)
  
## Installation
  
Install Jenkins - https://www.jenkins.io/doc/book/installing/  

Initially a n2-standard-2 on GCE, 100GB disk. That may change.   

Manually create a jenkins:jenkins user with uid and gid of 150, so those values are predictable for use in containers.

Install the Jenkins package:  

```
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins
```

Java:

```
sudo apt update
sudo apt install fontconfig openjdk-21-jre
java -version
```

Create a swapfile:  

```
#!/bin/bash
set -x
cd /
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

#To make the change permanent open the /etc/fstab file:
#sudo vi /etc/fstab
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
```


 
Install nginx and SSL certificates:  
```  
apt-get install -y certbot nginx
mkdir -p /var/www/letsencrypt 
certbot certonly --webroot-path /var/www/letsencrypt --webroot -d jenkins2.cppalliance.org
```  
  
Create website:  
```  
server {  
    listen 80;  
    listen [::]:80;  
    server_name jenkins2.cppalliance.org;  
    location '/.well-known/acme-challenge' {  
        default_type "text/plain";  
        root /var/www/letsencrypt;  
    }  
    location / {  
         return 301 https://jenkins2.cppalliance.org:8443$request_uri;  
    }  
}  
  
server {  
listen 8443 ssl default_server;  
listen [::]:8443 ssl default_server;  
ssl_certificate /etc/letsencrypt/live/jenkins2.cppalliance.org/fullchain.pem;  
ssl_certificate_key /etc/letsencrypt/live/jenkins2.cppalliance.org/privkey.pem;  
#include snippets/snakeoil.conf;  
location / {  
include /etc/nginx/proxy_params;  
proxy_pass http://localhost:8080;  
proxy_read_timeout 90s;  
}  
}  
```  

In the Jenkins Dashboard, change the URL from http://jenkins2.cppalliance.org:8080/ to https://jenkins2.cppalliance.org:8443/

Install plugins:

Dashboard -> Manage Jenkins -> Plugins

- Docker plugin
- Docker pipeline
- Pipeline: AWS Steps
- AWS Credentials Plugin 
- Pipeline: GitHub
- Remote Jenkinsfile Provider
- Amazon EC2 plugin

Credentials:  

Add each of these credentials.  

While it may be convenient to have access to the same credentials already in use, and faster to set up, in fact all credentials can be recreated/regenerated/reassigned. The same exact credentials are not needed. Issue new tokens. Create new users. With permissions in the AWS and github accounts.  

github-cppalliance-bot . It's a "username with password".  In reality, username with a token. This is a github account , cppalliance-bot  

cppalliance-bot-aws-user, AWS credential access to S3. Permissions to S3. 

jenkinsec2plugin , AKIAQWC... , this is an "aws credential", with key/secret to launch instances in the cloud. While this could be
		the same as the previous cppalliance-bot-aws-user, it happens to be a separate user.  

nodejenkins-private-key - an ssh key, where you enter a private key, that will be used to ssh into the auto-scaled cloud nodes that 
       jenkinsec2plugin is launching.

Cloud:  

Manage Jenkins->Clouds->New Cloud  
name: cloud-jenkinspool1  
ec2 creds: AKIAQWC... (jenkinsec2plugin)  
region: us-east-1  
ec2-keypair: nodejenkins-private-key  
description: jenkinspool1  
ami: ami-0b1cd4177a6d9ee12 (will vary)  
size: t3xlarge  
security group names: jenkinsnode  
remote filesystem: /jenkins  
remote user: nodejenkins  
ssh port: 22  
labels: jenkinspool1  
usage: only when labels match  
idle termination: 6  
Advanced:  
executor: 1  
min: 0  
min: 0  
connection strategy: public dns  
host verification: off  
max uses: -1  

See docker/packer folder to run packer and generate the AMI.  The AMI id will be entered in the above Cloud configuration.  

The pool is referenced via the label jenkinspool1.

Not all jobs use the cloud pool. At the moment many doc previews are built locally on the jenkins host itself, using docker but not remote cloud agents. 

Install Docker. Add Jenkins to docker group. Restart jenkins.   

```
sudo apt install docker.io
sudo usermod -aG docker jenkins
```
  
  
### Nginx Setup
 
An Nginx proxy serves the doc previews from S3.  

The Nginx proxy function can reside on the main jenkins server, or in fact, anywhere it is installed.  There is no requirement for it to be colocated with jenkins.  

Currently, that server is running on the original machine jenkins.cppalliance.org. That is a coincidence, and does not mean it's restricted to only serving a subset of doc previews.  

On the Nginx server:  
 
Create wildcard dns:  
*.prtest.cppalliance.cppalliance.org CNAME to jenkins.cppalliance.org  
*.prtest2.cppalliance.cppalliance.org CNAME to jenkins.cppalliance.org  
  
Create an nginx site for previews:  
  
```  
server {  
    # Listen on port 80 for all IPs associated with your machine  
    listen 80 default_server;  
  
    # Catch all other server names  
    server_name _;  
  
    if ($host ~* ([0-9]+)\.(.*?)\.(.*)) {  
        set $pullrequest $1;  
        set $repo $2;  
    }  
  
    location / {  
        # This code rewrites the original request  
        # E.g. if someone requests  
        # /directory/file.ext?param=value  
        # from the coolsite.com site the request is rewritten to  
        # /coolsite.com/directory/file.ext?param=value  
        set $backendserver 'http://cppalliance-previews.s3-website-us-east-1.amazonaws.com';  
        # echo "$backendserver";  
  
        #CUSTOMIZATIONS  
        #news customization  
        if ($repo = "cppalliance" ) {  
          rewrite ^(.*)/news$ $1/news.html ;  
	  rewrite ^(.*)/people/([a-zA-Z0-9]+)$ $1/people/$2.html ;
        }  
  
        #FINAL REWRITE  
        rewrite ^(.*)$ $backendserver/$repo/$pullrequest$1 break;  
  
  
        # The rewritten request is passed to S3  
        proxy_pass http://cppalliance-previews.s3-website-us-east-1.amazonaws.com;  
        #proxy_pass $backendserver;  
        include /etc/nginx/proxy_params;  
        proxy_redirect /$repo/$pullrequest / ;  
    }  
}  
  
```  
  
### AWS Setup  
  
Turn on static web hosting on the bucket.  
Endpoint is http://cppalliance-previews.s3-website-us-east-1.amazonaws.com  
  
Add bucket policy  
  
```  
{  
    "Version": "2012-10-17",  
    "Statement": [  
        {  
            "Sid": "PublicReadGetObject",  
            "Effect": "Allow",  
            "Principal": "*",  
            "Action": "s3:GetObject",  
            "Resource": "arn:aws:s3:::cppalliance-previews/*"  
        }  
    ]  
}  
```  
  
Add permissions in IAM for cppalliance-bot  
  
```  
    "Version": "2012-10-17",  
    "Statement": [  
        {  
            "Effect": "Allow",  
            "Action": [  
                "s3:GetBucketLocation",  
                "s3:ListAllMyBuckets"  
            ],  
            "Resource": "*"  
        },  
        {  
            "Effect": "Allow",  
            "Action": [  
                "s3:ListBucket"  
            ],  
            "Resource": [  
                "arn:aws:s3:::cppalliance-previews"  
            ]  
        },  
        {  
            "Effect": "Allow",  
            "Action": [  
                "s3:PutObject",  
                "s3:GetObject",  
                "s3:DeleteObject"  
            ],  
            "Resource": [  
                "arn:aws:s3:::cppalliance-previews/*"  
            ]  
        }  
    ]  
}  
```  
  
## Jobs

Currently jobs are being migrated from jenkins.cppalliance.org to jenkins2.cppalliance.org.  

From Freestyle Projects -> to Multibranch Pipelines.

See the "earlier-version1/" directory here for details about the Freestyle projects.  

Over time, jobs should be moved to the current server (jenkins2.cppalliance.org) and use the newer Multibranch Pipeline methodology.  

See [inventory](inventory.md) for a list of jobs. (those which have been upgraded so far.)  

Each job will be configured to use a particular Jenkinsfile. The mapping of job->Jenkinfile is in inventory.md. One Jenkinsfile per job.  

A Jenkinsfile is composed of Groovy code and it's somewhat self-documenting since the steps are often in bash or simple if-else blocks.  

The Jenkinsfiles are stored in this repository, and called remotely by the server (jenkins2.cppalliance.org) using the Remote Jenkinsfile Provider Plugin.  

To update the Jenkinsfiles, modify them in this repo and check in. That is sufficient. The server retrieves them remotely from github.  

What must be done to create a new project in Jenkins, to build a new library's documentation?  

Dashboard -> New Item -> Multibranch Pipeline.  
Credentials: github-cppalliance-bot  
Repository HTTPS URL: https://github.com/boostorg/__repo__  
Pull requests: Trust Everyone  
Click to add a "Filter by name (with regular expression)". Add this entry to build all branches: (develop|master|PR-.*) . Add this entry to only build pull requests, which should be the choice for official Boost libraries: (PR-*)  
Build Configuration: by Remote Jenkinsfile Provider Plugin  
Script path: jenkinsfiles/standard_libraries_1 (or other)  
Repository URL: https://github.com/cppalliance/jenkins-ci    
Scan Periodically: 5 minutes  

On nginx, vhosts must be configured for each repo. At the moment, the Nginx proxy server is hosted on jenkins.cppalliance.org. It could be moved.   

SSH into jenkins.cppalliance.org, go to root/scripts, and run:  

```
./new_website.sh # for the develop and master previews  
./certbot2.sh # for the PR previews  
```

Certbot + Cloudflare seem to only support 15 domains per cert.  Create certbot3.sh, certbot4.sh, etc. as needed.  

Copies of these scripts are found in the nginx directory here in this repo.   
