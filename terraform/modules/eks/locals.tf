locals {
  # -----------------------------
  # Common tags and naming system
  # -----------------------------
  common_tags = merge(
    var.tags,
    {
      Name                                        = var.cluster_name
      Environment                                 = var.environment
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  # Resource name prefixes
  name_prefix = {
    cluster     = "${var.cluster_name}-cluster"
    node_group  = "${var.cluster_name}-node-group"
    iam_cluster = "${var.cluster_name}-cluster-role"
    iam_node    = "${var.cluster_name}-node-role"
    kms         = "${var.cluster_name}-eks-kms-key"
  }

  # Function for generating resource-specific tags
  resource_tags = { for resource_type in [
    "cluster",
    "node-group",
    "eks-kms-key",
    "oidc",
    "cluster-sg",
    "node-group-sg"
    ] : resource_type => merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-${resource_type}"
    }
  ) }

  # Define aliases for easier access
  cluster_tags       = local.resource_tags["cluster"]
  node_group_tags    = local.resource_tags["node-group"]
  kms_tags           = local.resource_tags["eks-kms-key"]
  oidc_provider_tags = local.resource_tags["oidc"]
  cluster_sg_tags    = local.resource_tags["cluster-sg"]
  node_sg_tags       = local.resource_tags["node-group-sg"]

  # IAM role tags
  iam_role_tags = {
    cluster = merge(
      local.common_tags,
      {
        Name = "${var.cluster_name}-cluster-role"
      }
    )
    node = merge(
      local.common_tags,
      {
        Name = "${var.cluster_name}-node-role"
      }
    )
  }

  # -----------------------------
  # Node Group Configuration
  # -----------------------------
  # Template for user data
  node_user_data_template = <<-EOT
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex
/etc/eks/bootstrap.sh ${var.cluster_name} \
    --container-runtime containerd \
    --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup=${var.cluster_name}-node-group'

--==MYBOUNDARY==--
EOT

  # -----------------------------
  # Security Group Rules
  # -----------------------------
  # Default rule structure
  sg_rule_defaults = {
    cidr_blocks              = null
    source_security_group_id = null
    self                     = null
  }

  # Security group ID mapping
  sg_mapping = {
    cluster    = aws_security_group.eks_cluster.id
    node_group = aws_security_group.eks_node_group.id
  }

  # Combined security group rule definitions
  sg_rules = {
    cluster_egress = [
      {
        description              = "Allow HTTPS to node security group"
        from_port                = 443
        to_port                  = 443
        protocol                 = "tcp"
        source_security_group_id = "node_group"
      },
      {
        description              = "Allow kubelet health checks"
        from_port                = 10250
        to_port                  = 10250
        protocol                 = "tcp"
        source_security_group_id = "node_group"
      },
      {
        description = "Allow DNS outbound traffic"
        from_port   = 53
        to_port     = 53
        protocol    = "udp"
        cidr_blocks = [var.vpc_cidr]
      }
    ],
    cluster_ingress = [
      {
        description              = "Allow worker nodes to communicate with control plane"
        from_port                = 443
        to_port                  = 443
        protocol                 = "tcp"
        source_security_group_id = "node_group"
      }
    ],
    node_egress = [
      {
        description              = "Allow HTTPS to control plane"
        from_port                = 443
        to_port                  = 443
        protocol                 = "tcp"
        source_security_group_id = "cluster"
      },
      {
        description = "Allow DNS outbound traffic within VPC"
        from_port   = 53
        to_port     = 53
        protocol    = "udp"
        cidr_blocks = [var.vpc_cidr]
      },
      {
        description = "Allow NTP outbound traffic to AWS Time Sync service"
        from_port   = 123
        to_port     = 123
        protocol    = "udp"
        cidr_blocks = ["169.254.169.123/32"]
      },
      {
        description = "Allow node-to-node communication"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        self        = true
      },
      {
        description = "Allow HTTPS outbound traffic to private subnets for package updates"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = var.private_subnet_cidrs
      },
      {
        description = "Allow HTTPS outbound traffic to AWS API endpoints"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = concat(
          ["169.254.169.254/32"],                 # EC2 metadata service
          [for s in var.private_subnet_cidrs : s] # VPC endpoints in private subnets
        )
      }
    ],
    node_ingress = [
      {
        description              = "Allow kubelet API from control plane"
        from_port                = 10250
        to_port                  = 10250
        protocol                 = "tcp"
        source_security_group_id = "cluster"
      },
      {
        description = "Allow node-to-node communication"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        self        = true
      },
      {
        description = "Allow pod networking within the cluster"
        from_port   = 1025
        to_port     = 65535
        protocol    = "tcp"
        self        = true
      },
      {
        description              = "Allow webhook callbacks from control plane"
        from_port                = 443
        to_port                  = 443
        protocol                 = "tcp"
        source_security_group_id = "cluster"
      }
    ]
  }
}
