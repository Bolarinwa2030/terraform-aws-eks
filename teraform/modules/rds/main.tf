# ──────────────────────────────────────────
# 1. SUBNET GROUP
# Tells RDS which subnets it can live in.
# We use private subnets — no internet route.
# RDS will be in one of these, chosen by AWS.
# ──────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name}-rds-subnet-group"
  }
}

# ──────────────────────────────────────────
# 2. SECURITY GROUP
# A firewall for RDS.
# Rule: ONLY accept connections on port 5432
# (PostgreSQL) from EKS worker nodes.
# Nothing else can connect — not even you
# directly from your laptop.
# ──────────────────────────────────────────
resource "aws_security_group" "rds" {
  name   = "${var.name}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_node_security_group_id]
  }

  # No outbound rules needed — RDS doesn't initiate connections
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-rds-sg" }
}

# ──────────────────────────────────────────
# 3. THE RDS INSTANCE
# PostgreSQL database.
# multi_az = true means AWS keeps a standby
# copy in another AZ. If the primary fails,
# it automatically promotes the standby.
# That's high availability.
# ──────────────────────────────────────────
resource "aws_db_instance" "main" {
  identifier = "${var.name}-postgres"

  engine         = "postgres"
  engine_version = "15"
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  allocated_storage     = 20     # GB
  max_allocated_storage = 100    # auto-scale storage up to 100GB if needed

  multi_az            = false    # set true in prod for high availability
  publicly_accessible = false    # never expose RDS to the internet
  skip_final_snapshot = true     # set false in prod so you keep a backup on delete

  backup_retention_period = 7    # keep 7 days of automatic backups
  deletion_protection     = false # set true in prod so you can't accidentally delete it

  tags = { Name = "${var.name}-postgres" }
}