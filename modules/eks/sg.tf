# Security Group for EKS Cluster - Define the SG without rules first
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  tags = local.cluster_sg_tags

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for EKS Node Group - Define the SG without rules first
resource "aws_security_group" "eks_node_group" {
  name_prefix = "${var.cluster_name}-node-group-"
  description = "Security group for EKS node group"
  vpc_id      = var.vpc_id

  tags = local.node_sg_tags

  lifecycle {
    create_before_destroy = true
  }
}

# Create security group rules using a single resource pattern with for_each
resource "aws_security_group_rule" "rules" {
  # Generate unique IDs for all rules
  for_each = merge(
    { for i, rule in local.sg_rules.cluster_egress : "cluster_egress_${i}" => merge(
      local.sg_rule_defaults,
      rule,
      {
        type              = "egress",
        security_group_id = local.sg_mapping.cluster,
        source_security_group_id = try(rule.source_security_group_id == "node_group" ? local.sg_mapping.node_group :
        rule.source_security_group_id == "cluster" ? local.sg_mapping.cluster : null, null)
      }
      )
    },
    { for i, rule in local.sg_rules.cluster_ingress : "cluster_ingress_${i}" => merge(
      local.sg_rule_defaults,
      rule,
      {
        type              = "ingress",
        security_group_id = local.sg_mapping.cluster,
        source_security_group_id = try(rule.source_security_group_id == "node_group" ? local.sg_mapping.node_group :
        rule.source_security_group_id == "cluster" ? local.sg_mapping.cluster : null, null)
      }
      )
    },
    { for i, rule in local.sg_rules.node_egress : "node_egress_${i}" => merge(
      local.sg_rule_defaults,
      rule,
      {
        type              = "egress",
        security_group_id = local.sg_mapping.node_group,
        source_security_group_id = try(rule.source_security_group_id == "node_group" ? local.sg_mapping.node_group :
        rule.source_security_group_id == "cluster" ? local.sg_mapping.cluster : null, null)
      }
      )
    },
    { for i, rule in local.sg_rules.node_ingress : "node_ingress_${i}" => merge(
      local.sg_rule_defaults,
      rule,
      {
        type              = "ingress",
        security_group_id = local.sg_mapping.node_group,
        source_security_group_id = try(rule.source_security_group_id == "node_group" ? local.sg_mapping.node_group :
        rule.source_security_group_id == "cluster" ? local.sg_mapping.cluster : null, null)
      }
      )
    }
  )

  # Common properties for all security group rules
  security_group_id = each.value.security_group_id
  type              = each.value.type
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol

  # Conditional properties
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  self                     = each.value.self
}
