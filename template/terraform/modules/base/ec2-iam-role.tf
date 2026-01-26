# Create AssumeRole IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.app_name}-${var.environment}-EC2S3ReadWriteRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create an instance profile for the role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.app_name}-${var.environment}-EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}

# Create ECR read policy for EC2 instances
resource "aws_iam_policy" "ecr_read_policy" {
  name        = "${var.app_name}-${var.environment}-ECRReadPolicy"
  description = "Policy to allow read access to an ECR repository"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:DescribeImageScanFindings"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the ECR policy to the ec2 role
resource "aws_iam_role_policy_attachment" "ecr_read_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ecr_read_policy.arn
}