resource "aws_s3_bucket" "amdocs_bucket" {
  bucket = "amdocs-6479fd0f"

  tags = {
    Name        = "AmdocsBucket"
    Environment = "Production"
  }


}

output "bucket_name" {
  value = aws_s3_bucket.amdocs_bucket.bucket
}