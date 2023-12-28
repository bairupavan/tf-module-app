resource "aws_security_group" "sg" {
  name        = "${var.name}-${var.env}-sg"
  description = "${var.name}-${var.env}-sg"
  vpc_id      = var.vpc_id

  # access these for only app subnets
  ingress {
    description = "APP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allow_app_cidr
  }

  # connecting through the ssh bastion(work station node)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_cidr
  }

  # outside access
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.name}-${var.env}-sg"
  }
}

# creating the ec2 launch template
resource "aws_launch_template" "template" {
  name                   = "${var.env}-${var.name}-lt"
  image_id               = data.aws_ami.centos.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg.id]
}

# creating the auto scaling group to scale instance based on the load
resource "aws_autoscaling_group" "asg" {
  name                = "${var.env}-${var.name}-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.subnet_ids
  target_group_arns = [aws_lb_target_group.alb_target_group.arn]

  # attaching the template for autoscaling group
  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  # tags
  dynamic "tag" {
    for_each = local.asg_tags
    content {
      key                 = tag.key
      propagate_at_launch = "true"
      value               = tag.value
    }
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  name     = "${var.env}-${var.name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags     = merge(var.tags, { Name = "${var.name}-${var.env}-tg" })
}
