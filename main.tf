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
      { Name = "${var.component}-${var.env}" , Monitor = "yes" }
    )

  }

  tag_specifications {
    resource_type = "spot-instances-request"
    tags = merge(
      var.tags ,
      { Name = "${var.component}-${var.env}" , Monitor = "yes" }
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
  name = "${var.component}-${var.env}-auto_scaling_group"
  desired_capacity = var.desired_capacity
  max_size = var.max_size
  min_size = var.min_size
  vpc_zone_identifier = var.subnets
  target_group_arns = [aws_lb_target_group.main.arn]

  launch_template {
    id = aws_launch_template.main.id
    version = "$Latest"
  }
  # here tags are not preferred instead individual tag are preferred
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.component}-${var.env}"
  }
}

resource "aws_autoscaling_policy" "asg-cpu-rule" {
  autoscaling_group_name = aws_autoscaling_group.main.name
  name                   = "CPU_Load_Detect" # Based on CPU utilisation we increase the load
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 20.0
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
    description = "PROMETHEUS"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.monitoring_nodes
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

resource "aws_lb_target_group" "main" {
  name = "${var.component}-${var.env}-targetgroup"
  port = var.port
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 5
    interval = 5
    timeout = 4
    path = "/health"
  }
  deregistration_delay = 30
  tags = merge(
    var.tags ,
    { Name = "${var.component}-${var.env}-target_group"}
  )
}

# Creation of CNAME record
resource "aws_route53_record" "CNAME_main" {
  zone_id = data.aws_route53_zone.domain.zone_id #saraldevops.site ki zone id mil jaegi
  name    = local.dns_name # frontend-dev.saraldevops.site
  type    = "CNAME"
  ttl     = 30 # response time
  records = [var.alb_dns_name] # to get the records
}

# adding forwarding listener rule # Forward action

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = var.listener_arn # coming from main.tf of roboshop-infra
  priority     = var.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = [local.dns_name]
    }
  }
}