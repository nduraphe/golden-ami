packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {}
variable "instance_type" {}
variable "base_ami" {}
variable "s3_software_bucket" {}
variable "install_script" {}
variable "ami_name" {}

source "amazon-ebs" "windows" {
  region                      = var.aws_region
  source_ami                  = var.base_ami
  instance_type               = var.instance_type
  iam_instance_profile        = "PackerBuildProfile"
  ami_name                    = var.ami_name
  associate_public_ip_address = true

  # ✅ Use SSM communicator instead of WinRM
  communicator = "ssm"

  ami_description = "Golden AMI built via Jenkins + Packer"

  tags = {
    Name      = var.ami_name
    CreatedBy = "Jenkins"
    BuildDate = "{{timestamp}}"
  }
}

build {
  sources = ["source.amazon-ebs.windows"]

  provisioner "powershell" {
    scripts = [var.install_script]
  }
}