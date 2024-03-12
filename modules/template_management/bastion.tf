# resource "aws_iam_role" "ssm_role" {
#   name = "ssm_role"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
#   role       = aws_iam_role.ssm_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "ssm_instance_profile" {
#   name = "ssm_instance_profile"
#   role = aws_iam_role.ssm_role.name
# }

# resource "aws_instance" "bastion" {
#   ami                         = data.aws_ami.latest_amazon_linux.id
#   instance_type               = var.bastion_instance_type
#   key_name                    = "bastion-rds-dev"
#   subnet_id                   = module.vpc.public_subnets[0]
#   vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
#   associate_public_ip_address = true
#   iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name

#   tags = {
#     Name = "bastion-instance-dev"
#   }
# }
