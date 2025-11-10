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
  ami_name                    = "Golden_AMI_Windows"
  associate_public_ip_address = true
  communicator = "winrm"
  winrm_username = "Administrator"
  winrm_use_ssl = true
  winrm_insecure = true   # only for testing
  winrm_timeout = "5m"
  ami_description             = "Golden AMI built via Jenkins + Packer"

  tags = {
    Name      = "Golden_AMI_Windows"
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