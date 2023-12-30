# creating the IAM role to provide accesses to instance
resource "aws_iam_role" "role" {
  name = "${var.name}-${var.env}-role" # role name for each instance

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "${var.name}-${var.env}-role"
  }
}

# creating the instance profile to attach to each instance
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.name}-${var.env}-instance-profile"
  role = aws_iam_role.role.name # attaching role to instance profile
}

# creating aws_iam_role_policy to access the aws ssm parameter store
resource "aws_iam_role_policy" "iam_role_policy" {
  name = "${var.name}-${var.env}-ssm-paramter-store-policy"
  role = aws_iam_role.role.id # attaching this policy to the role

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ssm:*",
          #          "ssm:GetParameterHistory",# 4 permissions are given
          #          "ssm:GetParametersByPath",
          #          "ssm:GetParameters",
          #          "ssm:GetParameter"
        ],
        "Resource" : "arn:aws:ssm:us-east-1:416622536569:parameter/${var.env}.${var.name}.*"
        # access to all the ARN path starts with env and component name
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "ssm:DescribeParameters",
        "Resource" : "*"
      }
    ]
  })
}
