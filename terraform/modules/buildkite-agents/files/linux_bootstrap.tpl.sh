#!/bin/bash -x

# This script will be placed in /var/lib/cloud/instances/*/user-data.txt
# This script will log to /var/log/user-data.log

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

timedatectl set-timezone Australia/Melbourne || exit 1

# working directory
work_dir="/tmp"
mkdir -p "$work_dir" && cd "$_"

# template file parameters
buildkite_agent_token="${buildkite_agent_token}"
hostname="${hostname}"

# set hostname
sudo hostnamectl set-hostname $hostname --static
sudo hostnamectl set-hostname $hostname --transient
sed -i "/^127.0.0.1 localhost/a 127.0.0.1 $hostname" /etc/hosts
sudo echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

# verify hostname
sudo hostnamectl

# yum update
sudo yum -y update

# add buildkite yum repository
sudo sh -c 'echo -e "[buildkite-agent]\nname = Buildkite Pty Ltd\nbaseurl = https://yum.buildkite.com/buildkite-agent/stable/x86_64/\nenabled=1\ngpgcheck=0\npriority=1" > /etc/yum.repos.d/buildkite-agent.repo'

# install buildkite agent
sudo yum -y install buildkite-agent

# configure buildkite agent token
sudo sed -i "s/xxx/$buildkite_agent_token/g" /etc/buildkite-agent/buildkite-agent.cfg

# start the buildkite agent
sudo systemctl enable buildkite-agent && sudo systemctl start buildkite-agent

# install docker
sudo yum -y install docker

# add the buildkite-agent user to the docker group
sudo usermod -aG docker buildkite-agent

# set permissions to avoid need for a reboot
sudo setfacl --modify user:buildkite-agent:rw /var/run/docker.sock

# enable and start the docker service
sudo systemctl enable docker.service
sudo systemctl start docker.service

# verify that buildkite-agent has access to Docker:
sudo -u buildkite-agent -H docker info
