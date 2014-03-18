#!/bin/bash

cat > "config.js" << EOF
/* SFTP credentials */
exports.config = {
  sftp: {
    host: "${SFTP_HOST}",
    username: "${SFTP_USERNAME}",
    password: "${SFTP_PASSWORD}"
  }
}
EOF
