#
# Packer template for jenkins instances
# The purpose of this step is to prepopulate the jenkins agents with the docker images, so they don't have
# to download multigigabyte images every time they launch. Jenkins will operate without packer, but there is
# a much longer delay while the docker images are pulled.
#
# Instructions:
#
# Whenever the docker images mentioned in this repo are modified and updated, packer should be re-run.
#
# export AWS_ACCESS_KEY_ID=_
# export AWS_SECRET_ACCESS_KEY=_
# packer build template-noble.pkr.hcl
#
# Use the AWS credentials for the "packer" IAM account, which has permissions in us-west-2, for isolation, and then copies
# the AMI to us-east for usage. A copy of the installed IAM policy can be found in this directory.
#
# : '
# curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
# sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
# sudo apt-get update && sudo apt-get install packer
# '

variable "ami_name" {
  type    = string
  default = "my-custom-ami"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks configure your builder plugins; your source is then used inside
# build blocks to create resources. A build block runs provisioners and
# post-processors on an instance created by the source.
source "amazon-ebs" "example" {
  # access_key    = "${var.aws_access_key}"
  ami_name      = "jenkins-noble-ami ${local.timestamp}"
  instance_type = "t2.xlarge"
  region        = "us-west-2"
  # region        = "eu-west-1"
  ami_regions   = ["us-east-1"]
  # secret_key    = "${var.aws_secret_key}"
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 60
    volume_type = "gp2"
    delete_on_termination = true
  }
  # source_ami    =  "ami-03d5c68bab01f3496"
  # either specify an exact ami, or use the ami_filter below. Both methods work. The filter is likely better.
  # source_ami = "ami-0ddf424f81ddb0720"


  # from terraform
  # source_ami_filter {
  #   filters = {
  #     name                = "*/ubuntu-noble-24.04-amd64-server-*"
  #     root-device-type    = "ebs"
  #     virtualization-type = "hvm"
  #   }
  #   most_recent = true
  #   owners      = ["099720109477"]
  # }

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      architecture = "x86_64"
      name =  "*/ubuntu-noble-24.04-amd64-server-*"
      # block-device-mapping.volume-type = "gp2"
      root-device-type = "ebs"
    }
    most_recent = true
    owners = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.example"]

  #"sudo bash -c \"echo deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable > /etc/apt/sources.list.d/docker.list\"",

  provisioner "shell" {
    inline = [
      "set -xe",
      "whoami",
      "PACKERUSERNAME=nodejenkins",
      "PACKERUSERID=1001",
      "PUBLICKEY=\"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgG1Vr4/8tKjae03NChazvoqoDPghZfXrtchQdqcUhFyxO9r+5kZGG6BMYEfGL37a1slhSkwlIlept2DClf/j8T4KCO8ZR6r7oyPdj4Dx3PwquxALCBEOGR4FgzdzioxF56DwQtBbSX7JSB9caMxh3HQ12EsEecSN+er8m77TzD8977lBu2oI8jQUtYfVVLyfuASD0v799zPl+IpS2/EPDYCbcMPHV3BJvRUuc5nmKgEcdxrTrnQhG13LB98it6jxSUgeVrRwg5LL8GDd0yugPkPS3/DmJ3i9Ugf/Ca9C/1kX+FbXdmyoHxbyKWqvCpK0g4vFnDkgs2QLSgxuI7bbB nodejenkins\"",
      "echo \"$PACKERUSERNAME ALL=(ALL) NOPASSWD:ALL\" | sudo tee /etc/sudoers.d/90-$PACKERUSERNAME",
      "sudo useradd -s /bin/bash -u $PACKERUSERID $PACKERUSERNAME",
      "sudo mkdir -p /home/$PACKERUSERNAME/.ssh",
      "echo $PUBLICKEY | sudo tee /home/$PACKERUSERNAME/.ssh/authorized_keys",
      "sudo chmod 600 /home/$PACKERUSERNAME/.ssh/authorized_keys",
      "sudo chown -R $PACKERUSERNAME:$PACKERUSERNAME /home/$PACKERUSERNAME",
      "sudo mkdir -p /jenkins",
      "sudo chown $PACKERUSERNAME:$PACKERUSERNAME /jenkins",
      "sleep 90",
      "sudo apt-get update",
      "sleep 15",
      "sudo apt-get install -y openjdk-21-jre-headless",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release build-essential python3-pip python3-venv",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli docker-ce-rootless-extras",
      "# considering moving gcovr to a docker container. Not running anything in the plain VM.",
      "# but for the moment, all both methods",
      "sudo python3 -m venv /opt/venv",
      "sudo chmod -R 777 /opt/venv",
      "export PATH=/opt/venv/bin:$PATH",
      "pip3 install gcovr",
      "sudo systemctl stop unattended-upgrades",
      "sudo systemctl disable unattended-upgrades",
      "sudo apt-get purge -y unattended-upgrades",
      "sudo systemctl disable apt-daily-upgrade.timer",
      "sudo systemctl stop apt-daily-upgrade.timer",
      "sudo systemctl disable apt-daily.timer",
      "sudo systemctl stop apt-daily.timer",
      "sudo usermod -a -G docker $PACKERUSERNAME",
      "# sudo docker pull cppalliance/tracing:nj5",
      "# sudo docker pull sdarwin/jsonbenchmarks:latest",
      "sudo docker pull cppalliance/boost_superproject_build:22.04-v1",
      "sudo docker pull cppalliance/boost_superproject_build:24.04-v1"
    ]
  }
}
