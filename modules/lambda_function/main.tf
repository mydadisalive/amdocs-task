provider "aws" {
  region = "il-central-1"
}

data "aws_s3_bucket" "amdocs_bucket" {
  bucket = "amdocs-6479fd0f"
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "IAM policy for Lambda function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "s3:GetObject",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::${data.aws_s3_bucket.amdocs_bucket.bucket}/*",
          "arn:aws:dynamodb:*:*:table/s3_to_dynamodb",
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_lambda_function" "s3_to_dynamodb" {
  function_name    = "s3_to_dynamodb"
  runtime          = "nodejs14.x"
  handler          = "index.handler"
  timeout          = 60
  memory_size      = 128
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = "${path.module}/index.js.zip"
  source_code_hash = filebase64("${path.module}/index.js.zip")

  environment {
    variables = {}
  }

  vpc_config {
    subnet_ids           = []
    security_group_ids   = []
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    data.aws_s3_bucket.amdocs_bucket,
    aws_iam_role.lambda_execution_role
  ]
}

resource "aws_s3_bucket_notification" "s3_to_lambda" {
  bucket = data.aws_s3_bucket.amdocs_bucket.bucket

  # Specify the Lambda function as the notification target
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_dynamodb.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.s3_to_dynamodb.arn}"
  principal = "s3.amazonaws.com"
  source_arn = "arn:aws:s3:::amdocs-6479fd0f"
}