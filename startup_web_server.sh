#! /bin/bash
sudo apt update
sudo apt install docker.io docker-compose -y
git clone https://github.com/SkyRexDev/docker-compose.git
cd docker-compose/
sudo docker-compose up