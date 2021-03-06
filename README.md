# k3eks
EKS Clusters Built with only whats required for fast and secure [Kubernetes](https://kubernetes.io) workloads

### Premise
[Amazon's EKS](https://aws.amazon.com/eks/) is great for handling the Kuberentes control plane & etcd, but it leaves some of the complexity of managing the Kubernetes nodes to the user. _Why not incorporate the management of the nodes themsleves back into feature-rich Kubernetes abstractions?_

By using the cloud native design of [k3os](https://k3os.io/) and coupling it with [Terraform](https://www.terraform.io/) and [ASGs](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html), we can decrease the "state" of our server layer and shift our complexity up to the Kubernetes layer. This essentially makes EKS as turn-key and fully managed as Azure's AKS and Google's GKE. 

### Design

![Image of Architecture](k3eks_v2.png)

### Terraform
TF plan will create ASG comprised of k3os workers that should bootstrap themselves into an EKS cluster

Eventual goal is to have Terraform create the EKS cluster as well for a "single-click" deploy of a Kubernetes stack. 

*Variables to set*
You will probably need to define the following TF vars (e.g. `terraform.tfvars`)

- aws_ami - AMI for k3os
- vpc_subnets - subnets that the ASG should deploy to
- vpc_id - VPC ID
- aws_profile - Local IAM profile for your `~/.aws/credentials` file. Additioanlly you can change this section of the TF plan to just use the default.
- aws_credentials_file - Path to AWS credentials file. Usually `~/.aws/credentials`.