#!/bin/bash
set -e

# Update system
yum update -y
yum install -y curl wget git

# Install MongoDB
cat > /etc/yum.repos.d/mongodb-org-6.0.repo << 'EOF'
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

yum install -y mongodb-org

# Enable and start MongoDB
systemctl enable mongod
systemctl start mongod

# Wait for MongoDB to be ready
sleep 5

# Initialize MongoDB database and collections
mongosh << 'EOF'
use travel_memory
db.trips.createIndex({ tripName: 1 })
db.users.createIndex({ email: 1 })
db.trips.insertOne({
  tripName: "Sample Trip",
  destination: "Europe",
  startDate: new Date("2024-01-01"),
  endDate: new Date("2024-01-15"),
  status: "completed"
})
db.users.insertOne({
  email: "admin@travelmemory.com",
  name: "Admin User",
  createdAt: new Date()
})
EOF

# Configure MongoDB to listen on all interfaces (for private subnet)
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf

# Restart MongoDB with new configuration
systemctl restart mongod

# Create backup directory
mkdir -p /var/backups/mongodb
chown mongod:mongod /var/backups/mongodb

# Create backup script
cat > /usr/local/bin/backup-mongodb.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/mongodb"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$DATE"

mkdir -p "$BACKUP_PATH"
mongodump --out="$BACKUP_PATH"

# Keep only last 7 days of backups
find "$BACKUP_DIR" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
EOF

chmod +x /usr/local/bin/backup-mongodb.sh

# Add daily backup cron job
echo "0 2 * * * /usr/local/bin/backup-mongodb.sh >> /var/log/mongodb-backup.log 2>&1" | crontab -

# Install CloudWatch agent for monitoring
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

echo "Database server initialization complete"
