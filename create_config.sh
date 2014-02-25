#!/bin/bash

cat > "config.js" << EOF
/* SFTP credentials */
exports.config = {
  host: "${SFTP_HOST}",
  username: "${SFTP_USERNAME}",
  password: "${SFTP_PASSWORD}"
}
EOF