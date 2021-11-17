#################
# CONTROL PLANE #
#################

resource "aws_eks_cluster" "primary" {
  count           = var.destroy == true ? 0 : 1
  name            = var.cluster_name
  role_arn        = aws_iam_role.control_plane[0].arn
  version         = var.k8s_version

  vpc_config {
    security_group_ids = [aws_security_group.worker[0].id]
    subnet_ids         = aws_subnet.worker[*].id
  }
 
  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_iam_role_policy_attachment.service,
  ]
}

resource "aws_eks_node_group" "primary" {
  count           = var.destroy == true ? 0 : 1
  cluster_name    = aws_eks_cluster.primary[0].name
  version         = var.k8s_version
  release_version = var.release_version
  node_group_name = "gitops-nodes"
  node_role_arn   = aws_iam_role.worker[0].arn
  subnet_ids      = aws_subnet.worker[*].id
  instance_types  = [var.machine_type]
  scaling_config {
    desired_size = var.min_node_count
    max_size     = var.max_node_count
    min_size     = var.min_node_count
  }
  depends_on = [
    aws_iam_role_policy_attachment.worker,
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.registry,
  ]
  timeouts {
    create = "15m"
    update = "1h"
  }
}

resource "aws_iam_role" "control_plane" {
  count = var.destroy == true ? 0 : 1
  name  = "gitops-lab-control-plane"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.control_plane[0].name
}

resource "aws_iam_role_policy_attachment" "service" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.control_plane[0].name
}

###########
# WORKERS #
###########

resource "aws_security_group" "worker" {
  count       = var.destroy == true ? 0 : 1
  name        = "gitops-worker-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.worker[0].id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "devops-catalog"
  }
  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_iam_role_policy_attachment.service,
  ]
  timeouts {
    delete = "15m"
  }
}

resource "aws_iam_role" "worker" {
  count           = var.destroy == true ? 0 : 1
  name               = "gitops-worker-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "worker" {
  count      = var.destroy == true ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker[0].name
}

resource "aws_iam_role_policy_attachment" "cni" {
  count      = var.destroy == true ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker[0].name
}

resource "aws_iam_role_policy_attachment" "registry" {
  count      = var.destroy == true ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker[0].name
}
