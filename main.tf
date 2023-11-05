resource "aws_instance" "instance" {
  ami = data.aws_ami.centos.image_id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
}