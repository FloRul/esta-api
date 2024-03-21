data "aws_ami_ids" "amazon_linux" {
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.project_name}-${var.environment}-bastion-profile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_ec2_instance_state" "bastion_state" {
  instance_id = aws_instance.bastion.id
  state       = var.bastion_state
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami_ids.amazon_linux.ids[0]
  instance_type = "t2.micro"

  vpc_security_group_ids      = var.bastion_sg_ids
  subnet_id                   = var.admin_subnet_id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  tags = {
    Name = "${var.project_name}-${var.environment}-bastion"
  }
  user_data = <<-EOF
#!/bin/bash
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
EOF
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

resource "aws_iam_role_policy_attachment" "bastion_role_policy_ssm" {
  role       = aws_iam_role.bastion_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_role_policy_ssm_default" {
  role       = aws_iam_role.bastion_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}
