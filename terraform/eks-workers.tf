data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.10-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  telepathy-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.telepathy.endpoint}' --b64-cluster-ca '${aws_eks_cluster.telepathy.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "telepathy" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.telepathy-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "t2.medium"
  name_prefix                 = "terraform-eks-telepathy"
  security_groups             = ["${aws_security_group.telepathy-node.id}"]
  user_data_base64            = "${base64encode(local.telepathy-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "telepathy" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.telepathy.id}"
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks-telepathy"
  vpc_zone_identifier  = ["${module.vpc.public_subnets}"]

  tag {
    key                 = "Name"
    value               = "terraform-eks-telepathy"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
