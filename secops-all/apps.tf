
# XXX probably need to find a way to use ref to choose branch and stuff?

module "nessus" {
  source = "github.com/18F/identity-secops-nessus"

  codebuild_arn = aws_iam_role.codebuild.arn
  codebuild_role_name = aws_iam_role.codebuild.name
  artifacts_bucket_id = aws_s3_bucket.artifacts.id
  eks_cluster_name = aws_eks_cluster.secops.name
  codepipeline_arn = aws_iam_role.codepipeline_role.arn
  codepipeline_bucket = aws_s3_bucket.codepipeline_bucket.bucket
  codepipeline_kmskey_arn = aws_kms_alias.pipelines3kmskey.arn
}

