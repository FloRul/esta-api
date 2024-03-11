data "aws_ami_ids" "amazon_linux" {
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami_ids.amazon_linux.ids[0]
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = var.admin_subnet_id
  # No public IP assignment (bastion won't be directly accessible)
  associate_public_ip_address = false
}

resource "aws_security_group" "bastion" {
  name = "bastion-sg"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Deny all public access
    cidr_blocks = ["0.0.0.0/0"] # Replace with actual range
  }
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion_ssm_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion_role_policy" {
  role       = aws_iam_role.bastion_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
