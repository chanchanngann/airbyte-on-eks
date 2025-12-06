#!/bin/bash

echo "cleaning .terraform folder..."
rm -rf .terraform
rm -f .terraform.lock.hcl
rm -f terraform.tfstate terraform.tfstate.backup

echo "DONE! You can run 'terraform init' again when needed."
