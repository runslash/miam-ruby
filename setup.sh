#!/bin/sh

STACK_NAME="miam-development-stack"

echo -n "DELETE STACK..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
echo "OK"

echo -n "CREATE STACK..."
aws cloudformation create-stack \
  --template-body file://aws-cf-template.json \
  --parameters ParameterKey=Environment,ParameterValue=development \
  --stack-name $STACK_NAME
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
echo "OK"
