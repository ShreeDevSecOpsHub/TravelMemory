# 🌍 TravelMemory Application - Cloud Deployment Guide

A comprehensive, production-ready guide detailing the step-by-step deployment and scaling of the MERN-stack **TravelMemory** application on AWS EC2, configured with a highly resilient architectural flow using Nginx, AWS Application Load Balancers, and Cloudflare DNS management.

---

## 🏗️ 1. Architecture Overview

To ensure high availability, security, and low latency, the system is deployed using a decoupled, reverse-proxied infrastructure:


```
           [ User Browser ]
                  │
                  ▼
           [ Cloudflare DNS ]
           (SSL/DDoS Proxy)
            ╱            ╲
 (Frontend)╱              ╲(Backend API)
          ▼                ▼
 [ Frontend EC2 ]   [ AWS Application Load Balancer ]
 (Nginx Static)           ╱                  ╲
                         ▼                    ▼
                [ Backend EC2 - Node 1 ]   [ Backend EC2 - Node 2 ]
                (Nginx Proxy -> PM2)       (Nginx Proxy -> PM2)
                         │                          │
                         └────────────┬─────────────┘
                                      ▼
                             [ MongoDB Atlas ]

```

```

### Key Components:
* **Edge Layer:** Cloudflare manages global DNS routing, enforces SSL encryption, and masks underlying infrastructure IPs.
* **Presentation Layer (Frontend):** React components are compiled into highly optimized static assets and served directly via high-performance Nginx web servers.
* **Application Layer (Backend):** Multiple clustered Node.js application instances are monitored globally by PM2 process managers running under local Nginx reverse proxies.
* **Traffic Distribution:** An AWS Application Load Balancer (ALB) balances traffic dynamically across multiple nodes, removing single points of failure (SPOF).

---

## 🛠️ Task 1: Backend Configuration

### Step 1: System Provisioning & Node Runtime Installation
SSH into your primary AWS EC2 Ubuntu instance and run system updates along with dependencies initialization:

``` bash
# Update and upgrade local package indexes
sudo apt update && sudo apt upgrade -y

# Download and run NodeSource setup script for Node.js v18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install core runtime stacks
sudo apt install -y nodejs nginx git

```

### Step 2: Source Code Acquisition & Server Dependency Installation

```bash
# Clone the remote TravelMemory codebase
git clone [https://github.com/UnpredictablePrashant/TravelMemory.git](https://github.com/UnpredictablePrashant/TravelMemory.git)

# Move into the server runtime directory
cd TravelMemory/backend

# Install required node modules and packages
npm install

```

### Step 3: Runtime Environment Variable Isolation

Create an isolated environment file to manage access tokens and database connection configurations securely:

```bash
nano .env

```

Inject the following settings into the `.env` file (adjusting the `MONGO_URI` to use your actual MongoDB Atlas cluster endpoint):

```env
PORT=3000
MONGO_URI=mongodb+srv://cloud_admin:SecurePass123@cluster0.mongodb.net/travelmemory?retryWrites=true&w=majority

```

### Step 4: Daemonizing Node Process via PM2 Manager

To avoid downtime when an SSH session closes, encapsulate the Node process within a PM2 process manager:

```bash
# Install PM2 Process Manager globally
sudo npm install -g pm2

# Run application thread mapping to index execution point
pm2 start index.js --name "travel-backend"

# Persist application process across OS system reboots
pm2 save
pm2 startup

```

### Step 5: Backend Nginx Gateway Configuration

Create an isolated Nginx virtual block configuration to route ingress public port `80` requests to local runtime port `3000`:

```bash
sudo nano /etc/nginx/sites-available/travel-backend

```

Paste the following configurations into the server block layout:

```nginx
server {
    listen 80;
    server_name backend.yourcustomdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

```

Enable the reverse-proxy virtual profile link and bounce Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/travel-backend /etc/nginx/sites-enabled/
sudo systemctl restart nginx

```

---

## 🔗 Task 2: Frontend and Backend Connection

### Step 1: Mapping API Network Endpoints

Navigate into your local frontend development file structure to link your web elements to the production domain endpoint:

```bash
cd ~/TravelMemory/frontend/src
nano urls.js

```

Adjust the export target to route away from your development `localhost` setup:

```javascript
// export const BACKEND_URL = "http://localhost:3000"; 
export const BACKEND_URL = "[http://backend.yourcustomdomain.com](http://backend.yourcustomdomain.com)"; 

```

### Step 2: Compiling Static UI Production Builds

```bash
cd ~/TravelMemory/frontend

# Install dependencies needed for client compilation
npm install

# Build compiled, optimized static application code assets
npm run build

```

### Step 3: Serving Client UI via Nginx Static Mapping

Create a virtual structural host file mapping directly to the client build outputs:

```bash
sudo nano /etc/nginx/sites-available/travel-frontend

```

Apply the following explicit serving rules:

```nginx
server {
    listen 80;
    server_name yourcustomdomain.com [www.yourcustomdomain.com](https://www.yourcustomdomain.com);

    root /home/ubuntu/TravelMemory/frontend/build;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}

```

Link the execution profile path, check for configuration errors, and restart Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/travel-frontend /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

```

---

## 📈 Task 3: Scaling the Application Infrastructure

To eliminate single points of failure (SPOF) and balance application server workloads, set up AWS scaling topologies:

1. **Build a Base Machine Snapshot Image (AMI):**
* On the AWS EC2 Management Console, open **Instances**.
* Select your configured machine, click **Actions** $\rightarrow$ **Image and templates** $\rightarrow$ **Create image**.


2. **Horizontal Scaling Group Expansion:**
* Launch a replica EC2 Server instance using your newly minted Custom AMI to copy the code configurations, PM2 profiles, and Nginx blocks over instantly.


3. **Application Load Balancer Deployment:**
* Create an EC2 **Target Group** utilizing instance mapping targets targeting internal Port `80`. Register both base server nodes.
* Provision an Internet-Facing **Application Load Balancer (ALB)** spanning your target regions, mapping ingress traffic listeners to feed incoming work pipelines smoothly into the target instance groups.



---

## 🌐 Task 4: Edge Routing Integration via Cloudflare

Point your custom public web domain name records into Cloudflare DNS matrices to securely wrap nodes behind proxy firewalls:

| Record Type | Hostname / Name | Value / Destination | TTL | Proxy State |
| --- | --- | --- | --- | --- |
| **A** | `@` (Root Apex) | `YOUR_FRONTEND_EC2_PUBLIC_IP` | Auto | 🟠 Proxied (Enabled) |
| **CNAME** | `backend` | `your-aws-alb-dns-string.amazonaws.com` | Auto | 🟠 Proxied (Enabled) |

---

## 🔍 Validation Checklist

Verify the integrity of your deployment steps using these validation tests:

* [ ] **Daemon Control:** Running `pm2 status` shows `travel-backend` in an online state.
* [ ] **Network Check:** Accessing `http://backend.yourcustomdomain.com/status` (or health ping targets) responds without syntax or tracking breaks.
* [ ] **Data Pipeline Loop:** Interacting with the application at `http://yourcustomdomain.com` allows entries to save, persist, and load cleanly across pages.

```

```
