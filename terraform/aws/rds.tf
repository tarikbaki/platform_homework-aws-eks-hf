resource "aws_security_group" "rds_backend" {
  name = "${var.environment}-Backend-Postgres-Rds-Sg"
  description = "${var.environment}-Backend-Postgres-Rds-Sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
    #cidr_blocks = [module.vpc.private_subnets_cidr_blocks]
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  } 
  ingress {
    description      = "Eks Cluster from VPC"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups = [module.eks_cluster.cluster_security_group_id]
  }
  ingress {
    description      = "Add bastion host from VPC to RDS "
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups = [aws_security_group.bastion_host_sg.id]
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "random_password" "rds_password_backend"{
  length           = 16
  special          = true
  override_special = "_!%^"
}
resource "aws_secretsmanager_secret" "postgres_rds_endpoint_backend" {
  name = "${var.environment}-backend-postgres-rds-endpoint"
}
resource "aws_secretsmanager_secret_version" "postgres_rds_endpoint_backend" {
  secret_id = aws_secretsmanager_secret.postgres_rds_endpoint_backend.id
  secret_string = module.postgresrds.db_instance_endpoint
}
resource "aws_secretsmanager_secret" "postgres_rds_password_backend" {
  name = "${var.environment}-backend-postgres-rds-password"
}
resource "aws_secretsmanager_secret_version" "postgres_rds_password_backend" {
  secret_id = aws_secretsmanager_secret.postgres_rds_password_backend.id
  secret_string = random_password.rds_password_backend.result
  #secret_string = "1234567Aa_"
}
module "postgresrds" {
  source = "registry.terraform.io/terraform-aws-modules/rds/aws"
  version = "4.3.0"
  identifier = "${var.environment}postgres"
  db_name = "maindb"
  username = "dbadmin"
  password = aws_secretsmanager_secret_version.postgres_rds_password_backend.secret_string
  create_random_password = false
  engine = "postgres"
  engine_version = "14.3"
  instance_class = "db.t4g.micro"
  multi_az = false
  allocated_storage = 50
  family = "postgres14"
  major_engine_version = "14"
  allow_major_version_upgrade = true
  auto_minor_version_upgrade = true
  create_db_parameter_group = true
  parameter_group_name = "${var.environment}postgresdb"
  parameter_group_use_name_prefix = false
  create_db_subnet_group = false
  db_subnet_group_name = module.vpc.database_subnet_group_name
  subnet_ids = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.rds_backend.id]
  maintenance_window = "Sun:00:00-Sun:03:00"
  backup_window = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group = true
  backup_retention_period = 0
  skip_final_snapshot = true
  deletion_protection = false
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  create_monitoring_role = true
  monitoring_interval = 60
  monitoring_role_name = "${var.environment}-backend-postgres_monitoring_role"
  monitoring_role_description = "${var.environment}-backend-postgres monitoring role"
  parameters = [
    {
      name = "autovacuum"
      value = 1
    },
    {
      name = "client_encoding"
      value = "utf8"
    }
  ]
}