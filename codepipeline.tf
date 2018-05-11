resource "aws_s3_bucket" "inventory-codepipeline-artifacts" {
  bucket_prefix = "inventory-codepipeline-artifacts"
  force_destroy = true
}

resource "aws_iam_role" "inventory-codepipeline-role" {
  name = "inventory-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "inventory-codepipeline-policy" {
  name = "inventory-codepipeline-policy"
  role = "${aws_iam_role.inventory-codepipeline-role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.inventory-codepipeline-artifacts.arn}",
        "${aws_s3_bucket.inventory-codepipeline-artifacts.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:DescribeChangeSet",
        "cloudformation:CreateChangeSet",
        "cloudformation:DeleteChangeSet",
        "cloudformation:DescribeStacks"
      ],
      "Resource": [
        "arn:aws:cloudformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stack/${var.stack_name}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "${aws_iam_role.inventory-codepipeline-cloudformation-role.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "inventory-codepipeline-cloudformation-role" {
  name = "inventory-codepipeline-cloudformation-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudformation.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "inventory-codepipeline-cloudformation-policy" {
  name = "inventory-codepipeline-cloudformation-policy"
  role = "${aws_iam_role.inventory-codepipeline-cloudformation-role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.inventory-codepipeline-artifacts.arn}",
        "${aws_s3_bucket.inventory-codepipeline-artifacts.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateChangeSet",
        "cloudformation:ExecuteChangeSet"
      ],
      "Resource": [
        "arn:aws:cloudformation:${data.aws_region.current.name}:aws:transform/Serverless-2016-10-31"
      ]
    }
  ]
}
EOF
}

resource "aws_codepipeline" "inventory-codepipeline" {
  name     = "inventory"
  role_arn = "${aws_iam_role.inventory-codepipeline-role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.inventory-codepipeline-artifacts.id}"
    type     = "S3"
  }

  # Disabled until we can sort out how to pass oauth.  This will need to be created manually.
  # stage {
  #   name = "Source"
  #
  #   action {
  #     name     = "Source"
  #     category = "Source"
  #     owner    = "ThirdParty"
  #     provider = "GitHub"
  #     version  = "1"
  #
  #     output_artifacts = ["source"]
  #
  #     configuration {
  #       Owner  = "PolarGeospatialCenter"
  #       Repo   = "inventory"
  #       Branch = "${var.branch}"
  #     }
  #   }
  # }

  stage {
    name = "FakeSource"

    action {
      name             = "S3Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      output_artifacts = ["source"]
      version          = "1"

      configuration {
        S3Bucket    = "${aws_s3_bucket.inventory-codepipeline-artifacts.id}"
        S3ObjectKey = "source.zip"
      }
    }
  }
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration {
        ProjectName = "inventory-build-project"
      }
    }
  }
  stage {
    name = "Deploy"

    action {
      name            = "CreateChangeSet"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CloudFormation"
      input_artifacts = ["build_output"]
      version         = "1"
      run_order       = 1

      configuration {
        ActionMode    = "CHANGE_SET_REPLACE"
        Capabilities  = "CAPABILITY_IAM"
        ChangeSetName = "${var.stack_name}-change"
        RoleArn       = "${aws_iam_role.inventory-codepipeline-cloudformation-role.arn}"
        StackName     = "${var.stack_name}"
        TemplatePath  = "build_output::packaged.yml"
      }
    }

    action {
      name      = "ExecuteChangeSet"
      category  = "Deploy"
      owner     = "AWS"
      provider  = "CloudFormation"
      version   = "1"
      run_order = 2

      configuration {
        ActionMode    = "CHANGE_SET_EXECUTE"
        ChangeSetName = "${var.stack_name}-change"
        RoleArn       = "${aws_iam_role.inventory-codepipeline-cloudformation-role.arn}"
        StackName     = "${var.stack_name}"
      }
    }
  }
}
