resource "aws_eks_cluster" "main" {
    name = var.cluster_name
    role_arn = aws_iam_role.cluster.arn
    version = var.kubernetes_version

vpc_config {
    subnet_ids = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access = true
}

depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
    ]
}


# OIDC PROVIDER = Thi is what allow pods to get AWS permission

data "tls_certificate" "eks" {
    url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
    client_id_list = ["sts.amazonaws.com"]
    thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
    url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# IAM ROLE FOR THE CLUSTER CONTROL 
# The EKS Cluster needs permission to manage AWS resources 

resource "aws_iam_role" "cluster" {
    name = "${var.cluster_name}-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "eks.amazonaws.com" }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
    role = aws_iam_role.cluster.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM ROLE FOR THE WORKER NODE 
# The EC2 servers that run pods also need AWS Permissions to pull docker image from ECR 
resource "aws_iam_role" "node" {
    name = "${var.cluster_name}-node-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
    for_each = toset([
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",  #Let node join cluster 
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",  #networking for pods 
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # Pull image from ECR 
    ])
    role = aws_iam_role.node.name 
    policy_arn = each.value
}

#THe node 

resource "aws_eks_node_group" "system" {
    cluster_name = aws_eks_cluster.main.name
    node_group_name = "system"
    node_role_arn = aws_iam_role.node.arn
    subnet_ids = var.private_subnet_ids
    instance_types = [var.node_group_system_instance_type]

    scaling_config {
        desired_size = 2
        min_size = 1
        max_size = 3
    }

    # Taint means not allow regular pods to access the SYSTEM NODE

    taint {
        key = "dedicated"
        value = "system"
        effect = "NO_SCHEDULE"
    }

    labels = {
        role = "system"
    }

    depends_on = [aws_iam_role_policy_attachment.node_policies]
}

resource "aws_eks_node_group" "app" {
    cluster_name = aws_eks_cluster.main.name
    node_group_name = "app"
    node_role_arn = aws_iam_role.node.arn
    subnet_ids = var.private_subnet_ids  # to fix after confirmation 
    instance_types = [var.node_group_app_instance_type]

    scaling_config {
        desired_size = 2
        min_size = 1
        max_size = 3
    }

    labels = {
        role = "app"
    }
    
    depends_on = [aws_iam_role_policy_attachment.node_policies]
}
