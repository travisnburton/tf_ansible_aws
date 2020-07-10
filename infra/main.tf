provider "aws" {
    region  = var.region
}

# Create EBS volume
resource "aws_ebs_volume" "hello_aws" {
    availability_zone = var.az
    size              = 1
    type              = "gp2"
    encrypted         = true

    tags = {
        Name = "hello_aws"
    }
}

# Import key pair to be used when creating EC2 instance
resource "aws_key_pair" "hello_aws" {
    key_name   = "hello_aws"
    public_key = file("~/.ssh/id_rsa.pub")
}

# Create Security Group allowing SSH and HTTP access to EC2
resource "aws_security_group" "hello_aws" {
    name        = "hello_aws"
    description = "Allow HTTP and SSH to EC2"

    ingress {
        description = "Allow HTTP globally"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow SSH globally"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "Allow all outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create EC2 instance using latest Amazon Linux 2 AMI
data "aws_ami" "amzn2_ami_latest" {
    most_recent = true
    owners      = ["amazon"]
    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

resource "aws_instance" "hello_aws" {
    ami                    = data.aws_ami.amzn2_ami_latest.id
    instance_type          = "t2.micro"
    availability_zone      = var.az                 
    vpc_security_group_ids = [aws_security_group.hello_aws.id]
    key_name               = aws_key_pair.hello_aws.id
    
    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                EOF
}

# Attach EBS volume to EC2
resource "aws_volume_attachment" "hello_aws" {
    device_name = "/dev/xvdf"
    volume_id   = aws_ebs_volume.hello_aws.id
    instance_id = aws_instance.hello_aws.id
}

# Assign Elastic IP to EC2 instance
resource "aws_eip" "hello_aws" {
    instance = aws_instance.hello_aws.id
    vpc      = true
}

