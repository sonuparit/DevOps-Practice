terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.66.1"
    }
  }

  backend "s3" {
    bucket = "batch3-demo-state-bucket"
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "batch3-demo-state-table"
  }

  # Upgrraded version - no dynamo_db table require
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "path/to/your/statefile.tfstate"
    region         = "us-east-1"
    encrypt        = true
    
    # Enable S3-native locking (replaces dynamodb_table)
    use_lockfile   = true 
  }
}
