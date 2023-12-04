resource "aws_dynamodb_table" "s3_to_dynamodb" {
  name           = "s3_to_dynamodb"
  billing_mode   = "PAY_PER_REQUEST"

  hash_key       = "id"
  range_key      = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "data"
    type = "S"
  }

  global_secondary_index {
    name = "data_index"
    hash_key         = "data"
    projection_type = "ALL"
  }

  tags = {
    Name        = "S3ToDynamoDBTable"
    Environment = "Production"
  }
}
