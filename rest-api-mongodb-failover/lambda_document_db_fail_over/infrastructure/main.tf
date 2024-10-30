provider "aws" {
  region = var.region
}
resource "aws_iam_policy" "allow_lambda_write_logs" {
  name = "lambda_${var.lambda_name}_allow_logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.lambda_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
        ],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_policy" "allow_lambda_fail_over_global_document_db_cluster" {
  name = "allow_lambda_${var.lambda_name}_fail_over_global_document_db_cluster"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "rds:FailoverGlobalCluster"
        Effect   = "Allow"
        Resource = [
          "arn:aws:rds::858290205983:global-cluster:ecommerce-ireland-cluster",
          var.mongo_db_cluster_id_ireland_region
        ]
      },
    ]
  })
}
resource "aws_iam_role" "lambda_role" {
  name = "lambda_${var.lambda_name}_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "logs_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.allow_lambda_write_logs.arn
}
resource "aws_iam_role_policy_attachment" "document_db_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.allow_lambda_fail_over_global_document_db_cluster.arn
}
data "aws_ecr_repository" "document_db_image_repository" {
  name = var.lambda_ecr_repository # Replace with your ECR repository name
}
resource "aws_lambda_function" "document_db_fail_over" {
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri = "${data.aws_ecr_repository.document_db_image_repository.repository_url}:${var.lambda_image_tag}"
  timeout = 30
}

provider "aws" {
  alias  = "east"  # Aliased provider for cross-region resources
  region = "us-east-1"
}
data "aws_sns_topic" "cross_region_topic" {
  provider = aws.east
  name     = var.sns_topic_name
  depends_on = [var.sns_topic_name]
}
resource "aws_sns_topic_subscription" "lambda_subscription_to_topic_arn" {
  provider  = aws.east
  topic_arn = data.aws_sns_topic.cross_region_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.document_db_fail_over.arn
}
resource "aws_lambda_permission" "allow_sns_invoke_lambda" {
  statement_id  = "AllowSNSToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.document_db_fail_over.arn
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.cross_region_topic.arn
}
