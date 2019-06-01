resource "aws_s3_bucket" "inventory_build_cache" {
  bucket = "${var.cache_bucket_name}"
  force_destroy = true
}

resource "aws_s3_bucket" "inventory-build-lambda-artifacts" {
  bucket_prefix = "inventory-build-lambda-artifacts-"
  force_destroy = true
}

resource "aws_iam_role" "inventory-codebuild-role" {
  name = "inventory-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "inventory-codebuild-policy" {
  name        = "inventory-codebuild-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "${aws_s3_bucket.inventory-build-lambda-artifacts.arn}*",
                "${aws_s3_bucket.inventory-codepipeline-artifacts.arn}*",
                "${aws_s3_bucket.inventory_build_cache.arn}*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
              "ssm:GetParameters"
            ],
            "Resource": [
                "arn:aws:ssm:::parameter/CodeBuild/*"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": [
              "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${aws_codebuild_project.inventory-build-project.name}",
              "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${aws_codebuild_project.inventory-build-project.name}:*"
            ]
        }
    ]
}
POLICY
}

resource "aws_iam_policy_attachment" "inventory-codebuild-policy-attachment" {
  name       = "inventory-codebuild-policy-attachment"
  policy_arn = "${aws_iam_policy.inventory-codebuild-policy.arn}"
  roles      = ["${aws_iam_role.inventory-codebuild-role.id}"]
}

resource "aws_codebuild_project" "inventory-build-project" {
  name          = "inventory-build-project"
  description   = "build project for inventory api"
  build_timeout = "5"
  service_role  = "${aws_iam_role.inventory-codebuild-role.arn}"


  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = "${var.cache_bucket_name}/cache"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:2.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "S3_BUCKET"
      "value" = "${aws_s3_bucket.inventory-build-lambda-artifacts.id}"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}
