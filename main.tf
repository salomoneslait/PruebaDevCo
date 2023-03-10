terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "devco_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "My VPC"
  }
}

resource "aws_subnet" "devco_subnet_1" {
  vpc_id     = aws_vpc.devco_vpc.id
  availability_zone = "us-east-1a"
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "devco_subnet_2" {
  vpc_id     = aws_vpc.devco_vpc.id
  availability_zone = "us-east-1b"
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "devco_subnet_3" {
  vpc_id     = aws_vpc.devco_vpc.id
  availability_zone = "us-east-1c"
  cidr_block = "10.0.3.0/24"
}

resource "aws_subnet" "devco_control_plane_subnet_1" {
  vpc_id     = aws_vpc.devco_vpc.id
  availability_zone = "us-east-1a"
  cidr_block = "10.0.4.0/24"
}

resource "aws_subnet" "devco_control_plane_subnet_2" {
  vpc_id     = aws_vpc.devco_vpc.id
  availability_zone = "us-east-1b"
  cidr_block = "10.0.5.0/24"
}

resource "aws_subnet" "devco_control_plane_subnet_3" {
  vpc_id     = aws_vpc.devco_vpc.id
  availability_zone = "us-east-1c"
  cidr_block = "10.0.6.0/24"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devco_vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.devco_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_subnet_1" {
  subnet_id      = aws_subnet.devco_subnet_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta_subnet_2" {
  subnet_id      = aws_subnet.devco_subnet_2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta_subnet_3" {
  subnet_id      = aws_subnet.devco_subnet_3.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta_control_plane_subnet_1" {
  subnet_id      = aws_subnet.devco_control_plane_subnet_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta_control_plane_subnet_2" {
  subnet_id      = aws_subnet.devco_control_plane_subnet_2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta_control_plane_subnet_3" {
  subnet_id      = aws_subnet.devco_control_plane_subnet_3.id
  route_table_id = aws_route_table.rt.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "devco_cluster"
  cluster_version = "1.24"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = aws_vpc.devco_vpc.id
  subnet_ids               = [aws_subnet.devco_subnet_1.id, aws_subnet.devco_subnet_2.id, aws_subnet.devco_subnet_3.id]
  control_plane_subnet_ids = [aws_subnet.devco_control_plane_subnet_1.id, aws_subnet.devco_control_plane_subnet_2.id, aws_subnet.devco_control_plane_subnet_3.id]

  # Self Managed Node Group(s)
  

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t2.micro"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t2.micro"]
      capacity_type  = "SPOT"
    }
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        }
      ]
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::257068966566:role/eks_role"
      username = "role1"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::257068966566:role/eks_role"
      username = "user1"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::257068966566:role/eks_role"
      username = "user2"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [
    "257068966566"
  ]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
