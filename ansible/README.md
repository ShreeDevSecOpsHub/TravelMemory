# Ansible Configuration and Deployment Guide for TravelMemory MERN Application

## Overview

This Ansible configuration automates the deployment and configuration of the TravelMemory MERN (MongoDB, Express, React, Node.js) application on AWS EC2 instances created by Terraform.

## Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory.ini            # Inventory file with hosts and variables
├── playbooks/
│   ├── main.yml            # Main orchestration playbook
│   ├── web-server.yml      # Web server setup playbook
│   ├── db-server.yml       # Database server setup playbook
│   ├── deploy.yml          # Application deployment playbook
│   └── security.yml        # Security hardening playbook
└── roles/
    ├── web-server/         # Node.js and application setup
    │   ├── tasks/
    │   ├── handlers/
    │   └── templates/
    ├── db-server/          # MongoDB setup and configuration
    │   ├── tasks/
    │   ├── handlers/
    │   └── templates/
    └── security/           # Security hardening
        ├── tasks/
        ├── handlers/
        └── templates/
```

## Prerequisites

1. **Terraform Infrastructure**: Two EC2 instances must be created:
   - **Web Server**: In public subnet (for Node.js, Express, React)
   - **Database Server**: In private subnet (for MongoDB)

2. **Ansible Installation**: Install Ansible on your local machine
   ```bash
   pip install ansible boto3 pymongo
   ```

3. **SSH Key Pair**: Have your AWS key pair (e.g., `durga-windows.pem`) in the ansible directory

4. **Python Modules**: Required on Ansible controller
   ```bash
   pip install pymongo python-dotenv pexpect
   ```

## Configuration

### Step 1: Update Inventory File

Edit `ansible/inventory.ini` and replace the IP addresses with actual values from Terraform outputs:

```ini
[webservers]
web_server ansible_host=YOUR_WEB_SERVER_PUBLIC_IP ...

[dbservers]
db_server ansible_host=YOUR_DB_SERVER_PRIVATE_IP ...
```

Get these values from Terraform:
```bash
cd infrastructure/
terraform output web_server_public_ip
terraform output db_server_private_ip
```

### Step 2: Set Variables

Update the following in `inventory.ini`:

```ini
[dbservers:vars]
mongodb_admin_password=YourAdminPassword
mongodb_password=YourAppPassword
```

Or pass them via command line:
```bash
-e mongodb_admin_password=YourPassword -e mongodb_password=YourPassword
```

### Step 3: SSH Key Configuration

Ensure your SSH key has proper permissions:
```bash
chmod 400 durga-windows.pem
```

## Running Playbooks

### 1. Full Stack Deployment (Recommended)

Deploy everything in order:
```bash
cd ansible/

# Run all setups
ansible-playbook playbooks/main.yml \
  -e mongodb_admin_password=admin123 \
  -e mongodb_password=appuser123 \
  -vvv
```

### 2. Individual Playbooks

#### Database Server Setup
```bash
ansible-playbook playbooks/db-server.yml \
  -e mongodb_admin_password=admin123 \
  -e mongodb_password=appuser123 \
  -v
```

#### Web Server Setup
```bash
ansible-playbook playbooks/web-server.yml \
  -e mongodb_password=appuser123 \
  -v
```

#### Application Deployment
```bash
ansible-playbook playbooks/deploy.yml -v
```

#### Security Hardening
```bash
ansible-playbook playbooks/security.yml -v
```

## Playbooks Explained

### 1. **web-server.yml**
- Updates system packages
- Creates application user (`nodejs`)
- Installs Node.js and NPM
- Clones MERN repository from GitHub
- Installs backend and frontend dependencies
- Creates environment configuration files
- Sets up PM2 for application management

### 2. **db-server.yml**
- Updates system packages
- Adds MongoDB repository
- Installs MongoDB 5.0
- Enables MongoDB authentication
- Creates admin and application users
- Secures MongoDB instance
- Configures remote access restrictions

### 3. **deploy.yml**
- Starts the application using PM2
- Configures PM2 to start on system boot
- Sets up application logs
- Verifies backend service availability

### 4. **security.yml**
- Configures firewall (firewalld) rules
- Hardens SSH configuration
  - Disables password authentication
  - Disables root login
  - Limits authentication attempts
- Installs and configures fail2ban for intrusion detection
- Sets up audit logging for compliance
- Enables automatic security updates

## Application Components

### Backend (Express.js)
- **Port**: 3000
- **Database**: MongoDB on database server
- **Environment Variables**:
  - `NODE_ENV`: development/production
  - `PORT`: 3000
  - `DB_URL`: MongoDB connection string
  - `CORS_ORIGIN`: Frontend origin

### Frontend (React)
- **Port**: 3000 (default React dev server)
- **Build**: Automatic via npm
- **Environment Variables**:
  - `REACT_APP_API_URL`: Backend API URL
  - `REACT_APP_ENV`: Environment name

### Database (MongoDB)
- **Port**: 27017 (internal only)
- **Authentication**: Enabled
- **Users**: 
  - `admin`: Full administrative access
  - `mongoadmin`: Application access to database
- **Database**: `travelmemory`

## Connecting Services

### Web Server to Database
- Web server connects to database at: `mongodb://mongoadmin:password@<db-private-ip>:27017/travelmemory`
- Connection configured in `.env` file created by Ansible
- MongoDB security group allows access only from web server

### Frontend to Backend
- Frontend configured to connect to backend at configured API URL
- Express backend provides REST API endpoints
- CORS configured to allow frontend requests

## Verification Steps

### 1. SSH into Web Server
```bash
ssh -i durga-windows.pem ec2-user@WEB_SERVER_PUBLIC_IP

# Check Node.js
node --version
npm --version

# Check application status
pm2 status
pm2 logs
```

### 2. SSH into Web Server, then Database Server
```bash
ssh -i durga-windows.pem ec2-user@WEB_SERVER_PUBLIC_IP
ssh -i durga-windows.pem ec2-user@DB_SERVER_PRIVATE_IP

# Check MongoDB
systemctl status mongod
mongo -u admin -p --authenticationDatabase admin
```

### 3. Test Backend API
```bash
curl http://WEB_SERVER_PUBLIC_IP:3000/api/trips

# Expected response from Express backend
```

### 4. Test Frontend
Open browser and navigate to:
```
http://WEB_SERVER_PUBLIC_IP:3000
```

## Troubleshooting

### MongoDB Connection Issues
```bash
# Check MongoDB logs
tail -f /var/log/mongodb/mongod.log

# Check database connectivity
mongo mongodb://mongoadmin:password@DB_IP:27017/travelmemory --authenticationDatabase admin
```

### Node.js Application Issues
```bash
# Check PM2 logs
pm2 logs travelmemory-backend
pm2 logs travelmemory-frontend

# Check application status
pm2 status

# Restart application
pm2 restart all
```

### SSH/Security Issues
```bash
# Check SSH configuration
sshd -T

# Check firewall rules
firewall-cmd --list-all

# Check fail2ban
fail2ban-client status sshd
```

### Ansible Execution Issues
```bash
# Run with verbose output
ansible-playbook playbooks/main.yml -vvv

# Check inventory connectivity
ansible all -m ping

# Run a specific role
ansible-playbook playbooks/web-server.yml --tags "webserver"
```

## Security Best Practices

1. **Change Default Passwords**: Update MongoDB and SSH users
2. **Firewall**: Restrict access to necessary ports only
3. **SSH Keys**: Use strong SSH key and protect it
4. **Logs**: Regularly check audit and application logs
5. **Updates**: Keep system packages updated
6. **HTTPS**: Configure SSL/TLS for production
7. **Authentication**: Enable multi-factor authentication where possible

## Environment Variables

### Backend (.env)
```
NODE_ENV=development
PORT=3000
DB_URL=mongodb://mongoadmin:password@db-server:27017/travelmemory
CORS_ORIGIN=http://localhost:3000
API_URL=http://localhost:3000
```

### Frontend (.env)
```
REACT_APP_API_URL=http://localhost:3000
REACT_APP_ENV=development
```

## Post-Deployment

### 1. Test Application
- Navigate to web server public IP in browser
- Test API endpoints
- Verify database connectivity

### 2. Setup Monitoring
```bash
# Use PM2 Plus for monitoring
pm2 plus

# Or setup CloudWatch integration
```

### 3. Configure Backups
```bash
# Backup MongoDB
mongodump -u admin -p --db travelmemory --out /backups
```

### 4. Setup CI/CD Pipeline
Configure automated deployments via:
- Azure Pipelines (as in `azure-pipelines.yml`)
- GitHub Actions
- GitLab CI/CD

## Support and Documentation

- **Terraform**: See `infrastructure/` directory
- **MERN App**: See `backend/` and `frontend/` directories
- **Ansible Docs**: https://docs.ansible.com/
- **MongoDB Docs**: https://docs.mongodb.com/
- **Node.js Docs**: https://nodejs.org/

## Notes

- All playbooks are idempotent and can be run multiple times safely
- Use `-e` flag to override variables at runtime
- Add `--check` flag to dry-run playbooks
- Add `-vvv` flag for detailed debugging
- Ensure EC2 security groups are properly configured before running Ansible

## Next Steps

1. Complete Terraform infrastructure deployment
2. Get output values (IP addresses) from Terraform
3. Update `inventory.ini` with actual IPs
4. Run base playbooks for setup
5. Set up additional security measures as needed
6. Deploy application using deploy.yml
7. Monitor and maintain the infrastructure
