variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "eks_cluster_name" {
  type    = string
  default = "dev-vinmec-cluster"
}

variable "private_subnets_id" {
  type    = list(string)
  default = ["subnet-03edaa1eef7f2a3e7", "subnet-08d29f3e6a6b267b1"]
}

variable "public_subnets_id" {
  type    = list(string)
  default = ["subnet-010894193d47a0ce9", "subnet-081e560d30829197d"]
}