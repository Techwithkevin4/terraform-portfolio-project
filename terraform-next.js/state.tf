terraform {
  backend "s3" {
    bucket       = "ro-my-website-state"
    key          = "terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
