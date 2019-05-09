variable "worker_instance_type" {default="t2.medium"}

variable "aws_ami" {}

variable "initial_cluster_size" {
    default = "3"
  
}

variable "max_cluster_size" {
    default = "5"
  
}

variable "min_cluster_size" {
    default = "2"
  
}

variable "vpc_subnets" {
  type="list"
}

variable "vpc_id" {
  
}

variable "aws_profile" {
  
}

variable "aws_region" {
  default="us-east-1"
}

variable "aws_credentials_file" {
  
}

provider "aws" {
  shared_credentials_file = "${var.aws_credentials_file}"
  profile                 = "${var.aws_profile}"
  region                  = "${var.aws_region}"
}

resource "random_string" "rand" {
  length = 4
  special = true
  override_special = ""
}

resource "aws_iam_role" "eks_worker_nodes" {
  name = "eks_worker_nodes"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  role       = "${aws_iam_role.eks_worker_nodes.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks-service-policy" {
  role       = "${aws_iam_role.eks_worker_nodes.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_instance_profile" "eks_worker_nodes" {
  name = "eks_worker_nodes"
  role = "${aws_iam_role.eks_worker_nodes.name}"
}

resource "aws_security_group" "kube-worker" {
  name        = "kube-worker"
  description = "k3eks kube-worker"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

}
resource "aws_launch_configuration" "kube-worker" {
  name_prefix = "worker-"

  image_id                    = "${var.aws_ami}"
  instance_type               = "${var.worker_instance_type}"
  security_groups             = ["${aws_security_group.kube-worker.id}"]
  iam_instance_profile        = "${aws_iam_role.eks_worker_nodes.arn}"
  user_data = "${file("cloud-config.yml")}"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_placement_group" "kube" {
  name     = "kube"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "k3eks-test" {
  name                      = "k3eks-test-${random_string.rand.result}"
  max_size                  = "${var.max_cluster_size}"
  min_size                  = "${var.min_cluster_size}"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = "${var.initial_cluster_size}"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.kube-worker.name}"
  vpc_zone_identifier       = "${var.vpc_subnets}"


  tag {
    key                 = "Name"
    value               = "k3eks-worker"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "lorem"
    value               = "ipsum"
    propagate_at_launch = false
  }
}