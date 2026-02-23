#!/bin/bash
set -e

# Update system
yum update -y
yum install -y curl wget git

# Install Node.js 18
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install Nginx
amazon-linux-extras install nginx1 -y

# Create application directory
mkdir -p /var/www/travel-memory
cd /var/www/travel-memory

# Create a simple Express app
cat > app.js << 'EOF'
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date() });
});

app.get('/api/status', (req, res) => {
  res.json({ 
    status: 'running', 
    service: 'TravelMemory Web Server',
    timestamp: new Date()
  });
});

app.post('/api/trips', (req, res) => {
  res.json({ message: 'Create trip endpoint', data: req.body });
});

app.get('/api/trips', (req, res) => {
  res.json({ trips: [] });
});

app.listen(3001, () => {
  console.log('Server running on port 3001');
});
EOF

# Install dependencies
npm init -y
npm install express cors

# Create systemd service for Node.js app
cat > /etc/systemd/system/travel-memory.service << 'EOF'
[Unit]
Description=TravelMemory Web Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/travel-memory
ExecStart=/usr/bin/node /var/www/travel-memory/app.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable travel-memory
systemctl start travel-memory

# Configure Nginx as reverse proxy
cat > /etc/nginx/conf.d/travel-memory.conf << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://localhost:3001/health;
        access_log off;
    }
}
EOF

# Enable and start Nginx
systemctl enable nginx
systemctl start nginx

echo "Web server initialization complete"
