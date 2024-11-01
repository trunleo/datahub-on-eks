provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "5.8.1"

#   name = "dev-vinmec-vpc"
#   cidr = "10.0.0.0/16"

#   azs = slice(data.aws_availability_zones.available.names, 0, 3)

#   private_subnets = var.private_subnets
#   public_subnets  = var.public_subnets

#   enable_nat_gateway   = true
#   single_nat_gateway   = true
#   enable_dns_hostnames = true

#   private_subnet_tags = {
#     "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
#     "kubernetes.io/role/internal-elb"               = "1"
#   }

#   public_subnet_tags = {
#     "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
#     "kubernetes.io/role/elb"                        = "1"
#   }
# }
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.eks_cluster_name
  cluster_version = "1.30"

  # cluster_endpoint_private_access = true
  cluster_endpoint_public_access = true
  # cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = "vpc-0ee4c1a66725b1d42"
  subnet_ids               = var.private_subnets_id
  control_plane_subnet_ids = var.public_subnets_id
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    datahub = {
      name           = "datahub"
      instance_types = ["m5a.xlarge"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      capacity_type  = "ON_DEMAND"
      ebs_optimized  = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 50
            volume_type = "gp3"
          }
        }
      }

      labels = {
        WorkerType    = "ON_DEMAND"
        NodeGroupType = "core"
      }
    }
  }

  fargate_profiles = {
    default = {
      name = "dev-vinmec-fargate-profile"
      selectors = [
        {
          namespace = "datalake"
        }
      ]
      tags = {
        Environment = "dev"
        Terraform   = "true"
        Compute     = "fargate"
      }
      labels = {
        "node.kubernetes.io/compute" = "fargate"
      }
    }
  }
}








