data "aws_ami" "ami" {
  most_recent = true
  name_regex = "devops-practice-with-ansible-my-local-image"
  owners = ["self"]
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

