#!/bin/bash
# update rest-api-docker image
AWS_REGION=$1
ACCOUNT_ID=$2
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_REGION}.dkr.ecr.${AWS_REGION}.amazonaws.com
docker build . --tag "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/document-db-switch-over-lambda:latest"
docker push "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/document-db-switch-over-lambda:latest"
