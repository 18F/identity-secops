# provide some randomness so clusters can be created and destroyed easily.
resource "random_pet" "rand" {
  length = 1
}

resource "aws_s3_bucket" "spinnaker-s3" {
  bucket = "spinnaker-config-${random_pet.rand.id}"
  acl    = "private"

  lifecycle {
    prevent_destroy = false
  }
}
