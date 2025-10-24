#!/bin/sh

if $# < 1; then
    echo "Usage: $0 <output path>"
    exit 1
fi

openssl req -x509 -newkey rsa:4096 -keyout ${1}/key.pem -out ${1}/cert.pem -nodes 