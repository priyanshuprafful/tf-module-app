data "aws_ami" "ami" {
  most_recent = true
  name_regex = "devops-practice-with-ansible-my-local-image"
  owners = ["self"]
}


data "aws_caller_identity" "account" {
  # this is actually going to give the account id and we can use that in iam.tf file
}

data "aws_route53_zone" "domain" {
  name = var.dns_domain #
}

#data "template_file" "userdata" {
#  template = file("${path.module}/userdata.sh")
#  vars = {
#    component = var.component
#    env = var.env
#  }
#
#
#} This is not needed we are using another approach

