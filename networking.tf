
data "aws_availability_zones" "available" {
  state = "available"
}

#######
# VPC #
#######

resource "aws_vpc" "worker" {
  count      = var.destroy == true ? 0 : 1
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name"                                      = "gitops-vpc-worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

###########
# SUBNETS #
###########

resource "aws_subnet" "worker" {
  count      = var.destroy == true ? 0 : 3
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  vpc_id                  = aws_vpc.worker[0].id
  map_public_ip_on_launch = true
  tags = {
    "Name"                                      = "gitops-sub-worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_iam_role_policy_attachment.service,
  ]
  timeouts {
    delete = "15m"
  }
}

############
# GATEWAYS #
############

resource "aws_internet_gateway" "worker" {
  count      = var.destroy == true ? 0 : 1
  vpc_id = aws_vpc.worker[0].id
  tags   = {
   Name = "gitops-ig-worker"
  }
}

################
# ROUTE TABLES #
################

resource "aws_route_table" "worker" {
  count      = var.destroy == true ? 0 : 1
  vpc_id = aws_vpc.worker[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.worker[0].id
  }
}

resource "aws_route_table_association" "worker" {
  count      = var.destroy == true ? 0 : 3
  subnet_id      = aws_subnet.worker[count.index].id
  route_table_id = aws_route_table.worker[0].id
}
