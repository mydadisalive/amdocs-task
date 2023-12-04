provider "aws" {
  region = "il-central-1"
}

module "s3_bucket" {
  source = "./modules/s3_bucket"
}

module "dynamodb_table" {
  source = "./modules/dynamodb_table"
}

module "lambda_function" {
  source = "./modules/lambda_function"
}

