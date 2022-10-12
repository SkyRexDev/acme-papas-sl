#Initialize web-server.

#! /bin/bash
#Installs docker, docker-compose.
sudo apt update
sudo apt install docker.io docker-compose -y

#Fetches compose.yml from github
git clone https://github.com/SkyRexDev/docker-compose.git

#Initializes both containers
cd docker-compose/
sudo docker-compose up