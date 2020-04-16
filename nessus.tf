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
