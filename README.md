# Infrasctructure code for my Homelab

This repository serves as a infrasctructure template for a self-hosted server,
also called homelab! The idea behind this project is to get away from cloud
subscriptions and data collection without permission.  

It also serves as a great software learning project, as it covers many of the
computer science areas, such as software development, architecture, DevOps, 
CI/CD, Security, Monitoring, Deployment and Maintenance.  

# How it works  

My homelab has a self-hosted github runner connected to the repository. When 
a push triggers the GitHub actions deploy workflow, it copies this code to 
the server main SSD drive, runs the containers and necessary dependencies and 
will, in the future, test for any bugs or potential problems.  

TODO: the code should bind the docker containers data to the mounted disks 
(once I buy data disks). For now, they are binded to the data folder inside 
the main homelab folder in the server

# TODO

- Add RAID and Pooling for data backup and 3-2-1 backup methods
- Add Nginx reverse proxy for port routing (if necessary, as cloudflare does this already)
- Add more security measures, stronger firewall
- Add ansible playbooks for environment reprodutibility
- Fix monitoring logic, as it is yet not fully working
