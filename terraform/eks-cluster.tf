resource "aws_eks_cluster" "telepathy" {
  name     = "${var.cluster-name}"
  role_arn = "${aws_iam_role.telepathy-cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.telepathy-cluster.id}"]
    subnet_ids         = ["${module.vpc.public_subnets}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.telepathy-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.telepathy-cluster-AmazonEKSServicePolicy",
  ]
}
