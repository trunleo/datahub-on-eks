export cluster_name="dev-vinmec-cluster"
export region="ap-southeast-1"

aws eks --region $region update-kubeconfig --name $cluster_name
