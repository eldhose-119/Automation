
variable "access_key" {
    type = string
    default = " "  
}
variable "secret_key" {
     type = string
     default = " "
}

provider "aws" {
  region     = "us-west-2" 
  access_key     = var.access_key
  secret_key = var.secret_key
}


data "aws_ami" "ubuntu" {
  most_recent      = true
  owners           = ["099720109477"] 
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


resource "aws_security_group" "openstack_sg" {
  name        = "openstack_sg"
  description = "Allow SSH and necessary OpenStack ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform_key"
  public_key = file("~/.ssh/id_rsa.pub") 
}


resource "aws_instance" "controller" {
  count         = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.openstack_sg.name]
  key_name      = aws_key_pair.terraform_key.key_name

  tags = {
    Name = "controller-${count.index + 1}"
    Role = "controller"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              sudo sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              sudo sed -i 's/^PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              sudo mkdir -p /root/.ssh
              sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
              sudo chmod 700 /root/.ssh
              sudo chmod 600 /root/.ssh/authorized_keys
              sudo chown -R root:root /root/.ssh
              sudo systemctl restart sshd
              EOF
}


resource "aws_instance" "compute" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.openstack_sg.name]
  key_name      = aws_key_pair.terraform_key.key_name

  tags = {
    Name = "compute-${count.index + 1}"
    Role = "compute"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              sudo sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              sudo sed -i 's/^PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              sudo mkdir -p /root/.ssh
              sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
              sudo chmod 700 /root/.ssh
              sudo chmod 600 /root/.ssh/authorized_keys
              sudo chown -R root:root /root/.ssh
              sudo systemctl restart sshd
              EOF
}


resource "aws_instance" "storage" {
  count         = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.openstack_sg.name]
  key_name      = aws_key_pair.terraform_key.key_name

  tags = {
    Name = "storage-${count.index + 1}"
    Role = "storage"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              sudo sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              sudo sed -i 's/^PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              sudo mkdir -p /root/.ssh
              sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
              sudo chmod 700 /root/.ssh
              sudo chmod 600 /root/.ssh/authorized_keys
              sudo chown -R root:root /root/.ssh
              sudo systemctl restart sshd
              EOF
}

resource "local_file" "openstack_user_config" {
  content = templatefile("${path.module}/openstack_user_config.yml.tpl",
    {
      controllers = aws_instance.controller.*.public_ip,
      computes    = aws_instance.compute.*.public_ip,
      storages    = aws_instance.storage.*.public_ip
    }
  )
  filename = "${path.module}/openstack_user_config.yml"
}

# Controller IPs
output "controller_ips" {
  value = aws_instance.controller.*.public_ip
}

# Computes and Storage IPs
output "compute_public_ips" {
  value = aws_instance.compute.*.public_ip
}

output "storage_public_ips" {
  value = aws_instance.storage.*.public_ip
}
