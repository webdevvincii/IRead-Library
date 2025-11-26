#!/bin/bash

# =====================================================
# Library Management System - Database Backup Script
# =====================================================

echo "🔄 Library Management System - Database Backup"
echo "=============================================="
echo ""

# Configuration
BACKUP_DIR="backups"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="lms_backup_$DATE.sql"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Get database connection string
if [ -z "$DATABASE_URL" ]; then
    read -p "Enter your database connection string: " DATABASE_URL
fi

echo "📦 Starting backup..."
echo ""

# Full database backup
pg_dump "$DATABASE_URL" > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup completed successfully!"
    echo "📁 Backup file: $BACKUP_DIR/$BACKUP_FILE"
    
    # Get file size
    FILE_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo "📊 Backup size: $FILE_SIZE"
    
    # Compress backup
    echo ""
    echo "🗜️  Compressing backup..."
    gzip "$BACKUP_DIR/$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "✅ Backup compressed: $BACKUP_DIR/$BACKUP_FILE.gz"
        COMPRESSED_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE.gz" | cut -f1)
        echo "📊 Compressed size: $COMPRESSED_SIZE"
    fi
    
    # Clean up old backups (keep last 7 days)
    echo ""
    echo "🧹 Cleaning up old backups (keeping last 7 days)..."
    find "$BACKUP_DIR" -name "lms_backup_*.sql.gz" -mtime +7 -delete
    
    echo ""
    echo "📋 Recent backups:"
    ls -lh "$BACKUP_DIR" | grep "lms_backup"
    
else
    echo "❌ Backup failed!"
    exit 1
fi

echo ""
echo "✅ Backup process completed!"
echo ""
echo "💡 To restore from backup:"
echo "gunzip $BACKUP_DIR/$BACKUP_FILE.gz"
echo "psql \$DATABASE_URL < $BACKUP_DIR/$BACKUP_FILE"
