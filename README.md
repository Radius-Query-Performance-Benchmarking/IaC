# Radius Query Performance Benchmarking

The purpose of this repository is to provide the necessary Infrastructure as Code (IaC) scripts to reproduce the Radius Query Performance Benchmarking.

To automate our infrastructure provisioning and configuration tasks, we used two powerful Infrastructure as Code (IaC) tools: Terraform and Ansible. While Terraform excels at creating and managing infrastructure resources, Ansible's strengths lie in configuring and deploying software applications and services on that infrastructure.

The Terraform and Ansible scripts included in this repository are designed to create and configure the infrastructure and software necessary to run the benchmarking tests. By using these scripts, you should be able to quickly and consistently replicate the same environment used in the study, which will allow you to verify and reproduce the results.

After completing the [installation guide](#installation-guide), the results of the benchmark for the specific API and dataset you chose would be located in the `/root/results` directory of the machine used as the Ansible Control Node. The results would be in granular time-series format, which has metrics and timestamps for every point of the test to allow for deeper analysis. The k6 scripts that will be used for the load testing will be executed by a machine located in the same region as the selected API to minimize the network latency.

We chose DigitalOcean as our cloud hosting provider because of their generous free trial and their really good documentation.

## Prerequisites

- A DigitalOcean Personal Access Token, which you can [create](https://docs.digitalocean.com/reference/api/create-personal-access-token/) via the DigitalOcean control panel.
- An SSH key named `benchmark` added to your DigitalOcean account. The `init.yml` Ansible Playbook will generate an SSH key pair inside the IaC directory, [add](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-team/) the contents of the SSH public key `tf-digitalocean.pub` to DigitalOcean and give it the name of `benchmark`.

## Ansible Control Node Setup

The Control Node, the machine on which Ansible is installed, is responsible for executing Ansible Playbooks to configure the Ansible Hosts - the target servers that Ansible manages. The study was conducted using a machine operating on `Ubuntu 22.10 x64`. Unlike other configuration management tools, Ansible is agentless, meaning that it does not require any specialized software to be installed on the Ansible Hosts being managed.

### Installation Guide

- #### Update Packages

  `sudo apt update`

- #### Install pip3

  `sudo DEBIAN_FRONTEND=noninteractive apt install python3-pip -y`

- #### Install Ansible

  `pip3 install ansible==7.5.0`

- #### Clone IaC scripts

  `git clone https://github.com/Radius-Query-Performance-Benchmarking/IaC.git`

- #### Change Directory

  `cd ./IaC`

- #### Execute Ansible Playbook (change <your_email_address>)

  `ansible-playbook -e "email_address=<your_email_address>" init.yml`

- #### [Add](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-team/) the contents of the SSH public key `tf-digitalocean.pub` to your DigitalOcean account and give it the name of `benchmark`

  `cat tf-digitalocean.pub`

- #### Export Environment Variable (change <your_API_token>)

  `export DIGITALOCEAN_TOKEN=<your_API_token>`

- #### Clone the docker-compose files for the specific DBMS you intent to load test

  - `git clone https://github.com/Radius-Query-Performance-Benchmarking/PostGIS_docker-compose_Files.git ~/API`
  - `git clone https://github.com/Radius-Query-Performance-Benchmarking/MongoDB_docker-compose_Files.git ~/API`

- #### Change Directory

  `cd ./benchmark_env`

- #### Execute terraform apply

  `terraform apply --auto-approve`

- #### Get the IPv4 address of the `benchmark-env` Droplet

  `cat benchmark-env-ipv4`

- #### Setup the `benchmark-env` Droplet (change \<benchmark-env-ipv4\>)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<benchmark-env-ipv4>,' -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean setup.yml`

- #### Deploy docker-compose stack full dataset (change \<benchmark-env-ipv4\>)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<benchmark-env-ipv4>,' -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean docker-compose-up.yml`

  #### or you can optionally specify one of the subsets (change \<size\> with either 50k or 100k)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<benchmark-env-ipv4>,' -e 'dataset=<size>' -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean docker-compose-up.yml`

- #### Clone the code repository containing the k6 scripts

  `git clone https://github.com/Radius-Query-Performance-Benchmarking/k6.git ~/k6`

- #### Change Directory

  `cd ../load_test_env`

- #### Execute terraform apply

  `terraform apply --auto-approve`

- #### Get the IPv4 address of the `load-test-env` Droplet

  `cat load-test-env-ipv4`

- #### Setup the `load-test-env` Droplet (change \<load-test-env-ipv4\>)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<load-test-env-ipv4>,' -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean setup.yml`

- #### Run load test full dataset (change \<load-test-env-ipv4\> & \<benchmark-env-ipv4\>)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<load-test-env-ipv4>,' -e 'benchmark_env_ipv4=<benchmark-env-ipv4>'  -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean load_test.yml`

  #### or if you specified one of the subsets (change \<size\> with either 50k or 100k)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<load-test-env-ipv4>,' -e 'benchmark_env_ipv4=<benchmark-env-ipv4>' -e 'dataset=<size>' -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean load_test.yml`

## Analyze the Results

After the [installation guide](#installation-guide) has been completed, the results of the benchmark for the specific API and dataset you chose would be located in the `/root/results` directory of the machine used as the Ansible Control Node. The results would be in granular time-series format, which has metrics and timestamps for every point of the test to allow for deeper analysis.

You can copy the results from the Ansible Control Node machine using:

- Password Authentication (change <control_node_ip> & /path/to/local):

  `scp -o StrictHostKeyChecking=no -r root@<control_node_ip>:/root/results /path/to/local`

- SSH Key Authentication (change <control_node_ip>, /path/to/private_key & /path/to/local):

  `scp -o StrictHostKeyChecking=no -i /path/to/private_key -r root@<control_node_ip>:/root/results /path/to/local`

The scripts used to produce the boxplots and compute the confidence intervals for the study can be found [here](https://github.com/Radius-Query-Performance-Benchmarking/Analyze_Results).

## To load test another dataset of the same DBMS using the same `benchmark-env`

- #### Change Directory

  `cd /root/IaC/benchmark_env`

- #### Undeploy docker-compose stack full dataset (change \<benchmark-env-ipv4\>)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<benchmark-env-ipv4>,' -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean docker-compose-down.yml`

  #### or if you specified one of the subsets (change \<size\> with either 50k or 100k)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<benchmark-env-ipv4>,' -e 'dataset=<size>' -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean docker-compose-down.yml`

- #### Deploy docker-compose stack full dataset (change \<benchmark-env-ipv4\>)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<benchmark-env-ipv4>,' -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean docker-compose-up.yml`

  #### or you can optionally specify one of the subsets (change \<size\> with either 50k or 100k)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<benchmark-env-ipv4>,' -e 'dataset=<size>' -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean docker-compose-up.yml`

- #### Change Directory

  `cd ../load_test_env`

- #### Run load test full dataset (change \<load-test-env-ipv4\> & \<benchmark-env-ipv4\>)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<load-test-env-ipv4>,' -e 'benchmark_env_ipv4=<benchmark-env-ipv4>'  -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean load_test.yml`

  #### or if you specified one of the subsets (change \<size\> with either 50k or 100k)

  `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '<load-test-env-ipv4>,' -e 'benchmark_env_ipv4=<benchmark-env-ipv4>' -e 'dataset=<size>' -e 'pub_key=../tf-digitalocean.pub' --private-key ../tf-digitalocean load_test.yml`

## Release Resources

Don't forget to release the resources once you have finished with the load test - this will help ensure that the infrastructure is used efficiently and reduce the risk of unexpected billing charges.

- #### Change Directory

  `cd /root/IaC/benchmark_env`

- #### Execute terraform destroy

  `terraform destroy --auto-approve`

- #### Change Directory

  `cd /root/IaC/load_test_env`

- #### Execute terraform destroy

  `terraform destroy --auto-approve`

## Author

- Ioannis Papadatos (t8190314@aueb.gr)
