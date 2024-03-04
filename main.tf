resource "aws_launch_template" "main" {
  name = "${var.component}-${var.env}"
  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }
  image_id = data.aws_ami.ami.id

  instance_market_options {
    market_type = "spot"
  }

  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags ,
      { Name = "${var.component}-${var.env}"}
    )

  }
  #user_data = filebase64("${path.module}/userdata.sh")
  user_data = base64encode(templatefile("${path.module}/userdata.sh",
    {
      component = var.component
      env = var.env
    }))
}

# AWS auto Scaling groups
resource "aws_autoscaling_group" "main" {
  name = "${var.component}-${var.env}-auto scaling group"
  desired_capacity = var.desired_capacity
  max_size = var.max_size
  min_size = var.min_size
  vpc_zone_identifier = var.subnets

  launch_template {
    id = aws_launch_template.main.id
    version = "$Latest"
  }
  # here tags are not preferred instead individual tag are preferred
  tag {
    key                 = "Name"
    propagate_at_launch = false
    value               = "${var.component}-${var.env}"
  }
}


# creating a custom security group for our template and instances will follow this
resource "aws_security_group" "main" {
  name = "${var.component}-${var.env}-security group"
  description = "${var.component}-${var.env}-security group_description"
  vpc_id = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_cidr
  }

  ingress {
    description = "APP"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = var.allow_app_to
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags ,
    { Name = "${var.component}-${var.env}"}
  )

}