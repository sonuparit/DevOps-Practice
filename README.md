# AWS S3 Upload Monitoring with Lambda and CloudWatch

## Project Overview

This project demonstrates an **event‑driven AWS automation pipeline**
that detects file uploads in an Amazon S3 bucket and logs the activity
securely using AWS Lambda and Amazon CloudWatch.

The system automatically captures upload metadata such as: - Bucket
name - File name - File size - Upload timestamp

These logs are stored in **CloudWatch Logs**, enabling monitoring,
auditing, and troubleshooting.

This project showcases core **cloud‑native and DevOps skills**,
including event-driven architecture, serverless computing, AWS IAM
permissions, and structured logging.

---

# Architecture

User Upload → Amazon S3\
Amazon S3 Event Notification → AWS Lambda (Python + boto3)\
AWS Lambda → CloudWatch Logs

This architecture follows a **serverless, event-driven pattern**,
meaning no servers need to be managed.

---

# Why This Project Matters

Modern cloud systems require visibility and auditability. Tracking file
uploads is useful for:

- Security monitoring
- Compliance logging
- Data ingestion pipelines
- File processing workflows
- Infrastructure observability

This project demonstrates how cloud services can automatically respond
to storage events in real time.

---

# Technologies Used

- **AWS S3** -- Object storage and event trigger source
- **AWS Lambda** -- Serverless compute for automation
- **Python (boto3)** -- AWS SDK used for interacting with S3
- **Amazon CloudWatch Logs** -- Centralized logging service
- **IAM Roles and Policies** -- Secure permission management

---

# Project Workflow

1.  A user uploads a file to an S3 bucket.
2.  The S3 bucket triggers an **event notification**.
3.  The event invokes an **AWS Lambda function**.
4.  Lambda retrieves file metadata using boto3.
5.  The metadata is logged using structured JSON logging.
6.  Logs are automatically streamed to **CloudWatch Logs**.

---

# Step‑by‑Step Implementation

## 1. Create an S3 Bucket

1.  Open the AWS Console
2.  Navigate to **S3**
3.  Click **Create bucket**
4.  Choose a unique bucket name
5.  Keep default configuration

This bucket will store uploaded files and trigger events.

---

## 2. Create the Lambda Function

Navigate to **AWS Lambda → Create Function**

Configuration:

- Runtime: **Python 3.14**
- Function name: `s3-upload-logger`

Lambda will process the S3 event and log upload details.

---

## 3. Lambda Python Code

```python
import json
import boto3
import logging
from datetime import datetime

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')

def lambda_handler(event, context):

    try:
        # Loop through S3 event records
        for record in event['Records']:

            bucket_name = record['s3']['bucket']['name']
            object_key = record['s3']['object']['key']

            # Get object metadata
            response = s3.head_object(
                Bucket=bucket_name,
                Key=object_key
            )

            file_size = response['ContentLength']
            last_modified = response['LastModified']

            log_data = {
                "event": "file_upload_detected",
                "bucket": bucket_name,
                "file_name": object_key,
                "file_size_bytes": file_size,
                "last_modified": str(last_modified),
                "timestamp": str(datetime.utcnow())
            }

            # Secure structured logging
            logger.info(json.dumps(log_data))

        return {
            'statusCode': 200,
            'body': json.dumps('File upload logged successfully')
        }

    except Exception as e:

        logger.error(f"Error processing upload event: {str(e)}")

        return {
            'statusCode': 500,
            'body': json.dumps('Error logging upload')
        }
```

---

# 4. Configure IAM Permissions

The Lambda execution role must allow:

- Writing logs to CloudWatch
- Reading metadata from S3

Attach policies:

- **AWSLambdaBasicExecutionRole** (Auto added)
- **AmazonS3ReadOnlyAccess**

Production environments should use **least privilege policies**.

---

# 5. Configure S3 Event Notification

Open the S3 bucket and configure:

**Bucket → Properties → Event Notifications → Create Event**

Configuration:

Event Type: - PUT - POST

Destination: - Lambda Function

Lambda: `s3-upload-logger`

Now every file upload triggers the Lambda function.

---

# 6. Upload a Test File

Upload a file into the bucket.

Example:

test.txt

This action triggers the Lambda function automatically.

---

# 7. View Logs in CloudWatch

Navigate to:

CloudWatch → Logs → Log Groups

Find:

/aws/lambda/s3-upload-logger

Open the latest **log stream**.

Example output:

```json
[INFO]	2026-03-13T04:46:20.289Z	5257cc4c-bdef-46d6-a304-0627f64e094c
{
    "event": "file_upload_detected",
    "bucket": "demo-bucket-to-test-lambda",
    "file_name": "emoji-test.txt",
    "file_size_bytes": 669326,
    "last_modified": "2026-03-13 04:46:19+00:00",
    "timestamp": "2026-03-13 04:46:20.289248"
}
```

These logs confirm the automation is working.

---

# Security Considerations

For production environments:

- Use **least privilege IAM policies**
- Enable **S3 server access logging**
- Enable **CloudTrail auditing**
- Encrypt data with **SSE-S3 or SSE-KMS**
- Monitor logs using **CloudWatch Insights**

---

# Possible Enhancements

Future improvements could include:

- Store upload metadata in **DynamoDB**
- Send alerts via **SNS**
- Build monitoring dashboards with **CloudWatch Insights**
- Integrate with **security monitoring tools**
- Implement **file validation or malware scanning**

---

# DevOps Skills Demonstrated

This project demonstrates practical experience with:

- Event-driven cloud architecture
- Serverless automation
- AWS IAM security practices
- Infrastructure observability
- Python cloud automation using boto3

---

# Conclusion

This project implements a lightweight yet powerful serverless monitoring
solution using AWS services.

It highlights how modern cloud platforms enable automation and
observability with minimal infrastructure management.

Such patterns are commonly used in production environments for logging,
monitoring, and security auditing.

---

# Author

DevOps Project -- Serverless S3 Upload Monitoring
