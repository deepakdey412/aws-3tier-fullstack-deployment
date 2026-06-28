resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.db_subnet_group_ids

  tags = { Name = "${var.project_name}-${var.environment}-db-subnet-group" }
}

resource "aws_db_parameter_group" "mysql" {
  name   = "${var.project_name}-${var.environment}-mysql-params"
  family = "mysql8.0"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  parameter {
    name  = "long_query_time"
    value = "2"
  }
  parameter {
    name  = "log_output"
    value = "FILE"
  }

  tags = { Name = "${var.project_name}-${var.environment}-mysql-params" }
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-${var.environment}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  parameter_group_name   = aws_db_parameter_group.mysql.name

  # FREE TIER: No automated backups allowed
  # Use manual snapshots instead (see FREE-TIER.txt)
  backup_retention_period = 0  # Must be 0 for free tier
  backup_window           = "02:00-03:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  deletion_protection      = false
  skip_final_snapshot      = true  # Must be true for free tier
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYYMMDD", timestamp())}"

  enabled_cloudwatch_logs_exports = ["error"]

  auto_minor_version_upgrade = true
  publicly_accessible        = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-mysql"
    Environment = var.environment
  }
  
  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}
