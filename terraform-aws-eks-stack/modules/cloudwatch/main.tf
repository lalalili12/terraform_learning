resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks//cluster"
  retention_in_days = 30
}
