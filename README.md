# Travel Memory

# Part 1: Infrastructure Setup with Terraform

# 1. AWS Setup and Terraform Initialization: <br>
 - Configure AWS CLI and authenticate with your AWS account. <br>
     . Create new security credentials in the AWS console to perform the aws configure <br>
 
 <img width="933" height="372" alt="image" src="https://github.com/user-attachments/assets/b21d1fc1-9859-4de9-9f40-c23bead6b6de" />

  - Initialize a new Terraform project targeting AWS.

# 2. All the Terraform files are created for the following requirements. <br>

 - Create an AWS VPC with two subnets: one public and one private <br>
 - Set up an Internet Gateway and a NAT Gateway. <br>
 - Configure route tables for both subnets. <br>
# Terraform code is available in this path for the above requirements --> \Terraform\TravelMemory\infrastructure\main.tf <br>

<img width="1627" height="723" alt="image" src="https://github.com/user-attachments/assets/21feffcf-cb9e-4cc0-a14d-a6958366532d" />


# 3. EC2 Instance Provisioning <br>

- launching two instances as one with private and one with public subnets. <br>
- Created the key pair and attached it to the EC2 instances for SSH access. <br>
# Terraform code is available in this path for the above requirements --> \Terraform\TravelMemory\infrastructure\ec2_instances.tf <br>

<img width="1370" height="115" alt="image" src="https://github.com/user-attachments/assets/325c2585-21d6-4b07-90b8-227f8ffae66a" />


# 4. Security Groups and IAM Roles:

- Created the security groups for web and DB servers. <br>
- Created the IAM roles and policies for EC2 instances. <br>
# Terraform code is available in this path for the above requirements --> \Terraform\TravelMemory\infrastructure\iam_and_security.tf <br>

<img width="1042" height="637" alt="image" src="https://github.com/user-attachments/assets/74cd9071-00b8-4e0e-be59-e340261f1928" />

# terraform -version
<img width="877" height="153" alt="image" src="https://github.com/user-attachments/assets/5afe8569-b05e-4df8-8bf8-102fcbb164a8" />

# terraform init
<img width="897" height="346" alt="image" src="https://github.com/user-attachments/assets/e2231f90-260a-4b93-a1bf-f55fb4ffb810" />

# terraform plan -out=tfplan
<img width="873" height="397" alt="image" src="https://github.com/user-attachments/assets/f6a5b846-e427-4f1c-865d-89a64be476a2" />

# terraform apply tfplan

<img width="967" height="358" alt="image" src="https://github.com/user-attachments/assets/7b26ec1d-db4b-43f1-8696-dee8f51d780c" />

# Connected the EC2 instance with SSH (public instance only accessible from your IP). <br>

# Web server (Output the public IP of the web server EC2 instance.)

<img width="958" height="556" alt="image" src="https://github.com/user-attachments/assets/ac09e544-5c54-4c8a-bfd8-f58b78b943d7" />

# Part 2: Configuration and Deployment with Ansible

- MongoDB installation and configuration <br>
- Node.js and NPM setup <br>
- MERN application deployment <br>
- Environment configuration <br>
- Security hardening (firewall, SSH, fail2ban, audit) <br>





TravelMemory/
├── infrastructure/           # Terraform configuration
│   ├── main.tf              # VPC, Subnets, Gateways
│   ├── ec2_instances.tf     # EC2 instances
│   ├── iam_and_security.tf  # IAM and Security Groups
│   ├── variables.tf         # Variable definitions
│   ├── terraform.tfvars     # Variable values
│   └── outputs.tf           # Output values
│
├── ansible/                 # Ansible configuration
│   ├── ansible.cfg          # Ansible configuration
│   ├── inventory.ini        # Hosts and variables
│   ├── playbooks/           # Playbook files
│   │   ├── main.yml        # Orchestration
│   │   ├── web-server.yml  # Web setup
│   │   ├── db-server.yml   # Database setup
│   │   ├── deploy.yml      # Application deployment
│   │   └── security.yml    # Security hardening
│   └── roles/              # Ansible roles
│       ├── web-server/     # Node.js role
│       ├── db-server/      # MongoDB role
│       └── security/       # Security role
│
├── backend/                 # Express.js backend
├── frontend/               # React frontend
├── azure-pipelines.yml     # CI/CD pipeline
│
└── README.md               # This file



