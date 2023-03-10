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
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "devco_subnet_2" {
  vpc_id     = aws_vpc.devco_vpc.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "devco_subnet_3" {
  vpc_id     = aws_vpc.devco_vpc.id
  cidr_block = "10.0.3.0/24"
}

resource "aws_subnet" "devco_control_plane_subnet_1" {
  vpc_id     = aws_vpc.devco_vpc.id
  cidr_block = "10.0.4.0/24"
}

resource "aws_subnet" "devco_control_plane_subnet_2" {
  vpc_id     = aws_vpc.devco_vpc.id
  cidr_block = "10.0.5.0/24"
}

resource "aws_subnet" "devco_control_plane_subnet_3" {
  vpc_id     = aws_vpc.devco_vpc.id
  cidr_block = "10.0.6.0/24"
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
  self_managed_node_group_defaults = {
    instance_type                          = "t3.micro"
    update_launch_template_default_version = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  self_managed_node_groups = {
    one = {
      name         = "mixed-1"
      max_size     = 5
      desired_size = 2

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 10
          spot_allocation_strategy                 = "capacity-optimized"
        }

        override = [
          {
            instance_type     = "t3.micro"
            weighted_capacity = "1"
          },
          {
            instance_type     = "t3.micro"
            weighted_capacity = "2"
          },
        ]
      }
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.micro"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.micro"]
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
