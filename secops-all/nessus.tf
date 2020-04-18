# ECR repo for nessus
resource "aws_ecr_repository" "secops-nessus" {
  name                 = "secops-nessus"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# build project for nessus
resource "aws_codebuild_project" "nessus" {
  name           = "nessus"
  description    = "build_nessus"
  build_timeout  = "5"
  queued_timeout = "5"

  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true

    environment_variable {
      name  = "BUCKET"
      value = aws_s3_bucket.artifacts.id
    }
    environment_variable {
      name  = "IMAGE_REPO_URL"
      value = aws_ecr_repository.secops-nessus.repository_url
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.secops-nessus.name
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
    environment_variable {
      name  = "CLUSTER"
      value = aws_eks_cluster.secops.name
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/18F/identity-secops-nessus.git"
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "builds"
      stream_name = "nessus"
    }
  }

  tags = {
    Environment = "Test"
  }
}


# here is the codepipeline that builds/deploys it
resource "aws_codepipeline" "nessus" {
  name     = "nessus"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_alias.pipelines3kmskey.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner  = "18F"
        Repo   = "identity-secops-nessus"
        Branch = "master"
      }
    }
  }

  stage {
    name = "BuildTestDeploy"

    action {
      name             = "NessusBuildTestDeploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "nessus"
      }
    }
  }
}

# need this so that we can get the license key for nessus
resource "aws_iam_role_policy" "nessus" {
  role = aws_iam_role.codebuild.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:nessus-license-*",
      "Effect": "Allow"
    }
  ]
}
POLICY
}
