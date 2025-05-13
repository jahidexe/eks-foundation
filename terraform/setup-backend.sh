#!/bin/bash
set -e

# Variables - Change these to match your project
PROJECT="eks-foundation"
ENV="dev"
REGION="eu-west-1" # Ireland region
BUCKET_NAME="${PROJECT}-${ENV}-terraform-state"
DYNAMODB_TABLE="${PROJECT}-${ENV}-terraform-locks"
KMS_ALIAS="alias/${PROJECT}-${ENV}-terraform-key"

echo "Setting up Terraform S3 backend infrastructure in ${REGION}..."

# Create KMS Key for encrypting the S3 bucket contents
echo "Creating KMS key..."
KMS_KEY_ID=$(aws kms create-key --description "KMS key for Terraform state encryption" \
  --region $REGION \
  --tags TagKey=Project,TagValue=$PROJECT TagKey=Environment,TagValue=$ENV \
  --output json | jq -r '.KeyMetadata.KeyId')

echo "Creating KMS alias: $KMS_ALIAS..."
aws kms create-alias \
  --alias-name $KMS_ALIAS \
  --target-key-id $KMS_KEY_ID \
  --region $REGION

# Create S3 bucket with versioning and encryption
echo "Creating S3 bucket: $BUCKET_NAME..."
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION \
  --create-bucket-configuration LocationConstraint=$REGION

echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

echo "Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration \
  '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "aws:kms",
          "KMSMasterKeyID": "'$KMS_KEY_ID'"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'

# Add bucket policy to block public access
echo "Blocking public access to S3 bucket..."
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
  'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'

# Create DynamoDB table for state locking
echo "Creating DynamoDB table: $DYNAMODB_TABLE..."
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION \
  --tags Key=Project,Value=$PROJECT Key=Environment,Value=$ENV

echo "Terraform backend infrastructure setup complete!"
echo ""
echo "You can now use the S3 backend with these settings:"
echo "  bucket         = \"$BUCKET_NAME\""
echo "  key            = \"terraform.tfstate\""
echo "  region         = \"$REGION\""
echo "  dynamodb_table = \"$DYNAMODB_TABLE\""
echo "  encrypt        = true"
echo "  kms_key_id     = \"$KMS_ALIAS\""
echo ""
echo "Add these as GitHub secrets:"
echo "  TF_STATE_BUCKET   = $BUCKET_NAME"
echo "  TF_LOCK_TABLE     = $DYNAMODB_TABLE"
echo "" 