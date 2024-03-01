resource "aws_launch_template" "main" {
  name = "${var.component}-${var.env}"
#  iam_instance_profile {
#    name = "test"
#  }
  image_id = data.aws_ami.ami.id

  instance_market_options {
    market_type = "spot"
  }

  instance_type = var.instance_type

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