####################################
# SG for Bastion Host
####################################
resource "aws_security_group" "bastion_sg" {
  vpc_id = data.terraform_remote_state.stage1.outputs.vpc_id

  ingress {
    description = "SSH from my laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr] # replace with your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


####################################
# Bastion Host
####################################

resource "aws_instance" "bastion" {

  region                      = var.region
  ami                         = "ami-0357b3d964cbfbed6" # Amazon Linux 2023 AMI 2023.8.20250908.0 x86_64 HVM kernel-6.1, storage 8GiB gp3
  instance_type               = "t3.micro"
  subnet_id                   = data.terraform_remote_state.stage1.outputs.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = var.ec2_key_name

  root_block_device {
    volume_size = 10 # override default 8GiB
    volume_type = "gp3"
    # encrypted   = true   # ensures EBS volume encryption
    delete_on_termination = true # cleans up volume automatically with instance
  }

  tags = {
    Name = "${var.name_prefix}-bastion"
  }
}
