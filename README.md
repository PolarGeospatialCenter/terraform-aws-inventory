# terraform-aws-inventory

A terraform module for deploying the PolarGeospatialCenter/inventory api to AWS.

## Overview

Creates/updates
* codepipeline
* codebuild
* iam policies/roles


## Manual Steps (REQUIRED)

### Connect GitHub source

Disabled until we can sort out how to setup Oauth *properly*.
This will need to be created manually via the AWS console

```terraform
stage {
  name = "Source"
  action {
    name     = "Source"
    category = "Source"
    owner    = "ThirdParty"
    provider = "GitHub"
    version  = "1"

    output_artifacts = ["source"]

    configuration {
      Owner  = "PolarGeospatialCenter"
      Repo   = "inventory"
      Branch = "${var.branch}"
    }
  }
}
```
