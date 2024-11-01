# Deploy DataHub on AWS EKS

## Introduction
DataHub allows you to enable simple and scalable access to distributed data for computation, and to publish a dataset and make it available to a specific community, or worldwide, across federated sites.

## Quick-start

### Preperation
1. Clone the repository
```
git clone https://github.com/tutrungtranvn/datahub-on-eks.git
```
2. Move to folder
```
cd datahub-on-eks
```

### 1. Deploy AWS EKS with Terraform
* Modify the variables with exist `private subnet IDs` and `public subnet IDs` on [variable file](terraform/deploy-eks-cluster/create-eks-cluster/variables.tf)

```
variable "private_subnets_id" {
  type    = list(string)
  default = ["subnet-111111", "subnet-222222"]
}

variable "public_subnets_id" {
  type    = list(string)
  default = ["subnet-333333", "subnet-444444"]
}
```
* Modify [main file](terraform/deploy-eks-cluster/create-eks-cluster/main.tf) with exist `VPC ID`
```
vpc_id                   = "vpc-000000"
```

###  2. Deploy Kafka on EKS 
Kafka will be deployed on EKS node, we can replace it with the managed service such as AWS MSK,..

We use `helm` to deploy `Kafka`. The config file on [here](terraform/deploy-eks-cluster/create-eks-cluster/yaml-file/kafka-service.yaml)
```
helm upgrade --install kafka datahub/datahub-prerequisites --values ./yaml-file/kafka-service.yaml
```

### 3. Deploy DataHub and SetupJob for data source
The config file on [here](terraform/deploy-eks-cluster/create-eks-cluster/yaml-file/datahub-values.yaml)

```
helm upgrade --install datahub datahub/datahub -f ./yaml-file/datahub-values.yaml
```

### 4. Check DataHub UI with LoadBalancer

