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

# 1. Ansible Configuration
. Created 2 ec2 instances through terraform <br>
. Created the inventory.ini file with 2 IP's <br>
. Both the IP's are reaching via SSH <br>

# 2. Web Server Setup:
All packages are installed, and the repositories were cloned <br>
. Web Server (xx.xx.xx.138)
├── ✅ System updated with development tools <br>
├── ✅ Node.js v16.20.2 installed (via nvm) <br>
├── ✅ NPM v8.19.4 operational <br>
├── ✅ MERN repository cloned <br>
├── ✅ Backend dependencies (express, mongoose, etc.) <br>
└── ✅ Frontend dependencies (react, axios, etc.) <br>

# 3. Database Server Setup:
. System packages are installed <br>
. MongoDB is installed, and the container is active and accessible <br>

# Database configuration
Database Server: xx.xx.xxx.213:27017 <br>
Status: ✅ Running (Docker container) <br>
MongoDB Version: 4.4.30 <br>

# Application Account: 
Username: mongoadmin <br>
Password: changeme123 <br>
Database: travelmemory <br>
Roles: readWrite, dbAdmin <br>

# Connection String:
mongodb://mongoadmin:changeme123@xx.xxx.xxx.213:27017/travelmemory

# 4. Application Deployment:
. Backend and Frontend .env configuration files were created <br>
. Backend server started, and Frontend can communicate with the backend <br>

# Current Deployment Status:
Frontend Build: /home/ec2-user/travel-app/frontend/build/ <br>
Backend Config: /home/ec2-user/travel-app/backend/.env <br>
Database: Running at xx.xxx.xx.213:27017 <br>

Component	Port	Status	URL
Frontend (React)	3000	✅ RUNNING	http://xx.xx.xx.138:3000 <br>
Backend (Express)	5000	✅ RUNNING	http://xx.xx.xx.138:5000 <br>
Database (MongoDB)	27017	✅ RUNNING	xx.xx.xxx.213:27017 <br>

Able to deploy the travel memory application through Ansible

<img width="1511" height="962" alt="image" src="https://github.com/user-attachments/assets/60d49391-6adf-42cf-82c4-b6c0b80ebe46" />

Able to enter the trip details

<img width="1693" height="837" alt="image" src="https://github.com/user-attachments/assets/01c75acc-e2b8-4c86-a9e2-3f77fe2b3519" />


# 5. Security Hardening:

I've completed comprehensive security hardening for your TravelMemory MERN application. Here's what was delivered: <br>

  # 1. Infrastructure as Code (Terraform)
  [security_hardening.tf]  --> TravelMemory\infrastructure\security_hardening.tf) (400+ lines) <br>

  # 2. Server Hardening Scripts
  [security_hardening_web.sh] --> (TravelMemory\infrastructure\security_hardening_web.sh) (500+ lines) <br>

SSH hardening (root login disabled, key-based auth only) <br>
Firewall configuration (firewalld) <br>
Fail2ban intrusion detection (3 strikes, 1-hour ban) <br>
AIDE file integrity monitoring <br>
SELinux hardening <br>

. [security_hardening_db.sh]  --> (TravelMemory\infrastructure\security_hardening_db.sh) (400+ lines) <br>

MongoDB-specific security <br>
SSH hardening (same as web) <br>
Database authentication enforcement <br>
Network isolation <br>

