# Configure this backend for your management account before applying.
#
# terraform {
#   backend "s3" {
#     bucket         = "replace-with-tf-state-bucket"
#     key            = "control-tower/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "replace-with-tf-lock-table"
#     encrypt        = true
#   }
# }