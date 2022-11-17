# A random string to use as a password for the admin user
resource "random_string" "rds_pass" {
  length  = 24
  special = false
  upper   = true
}

# The RDS instance
resource "aws_db_instance" "rds" {
  allocated_storage           = 10
  max_allocated_storage       = 64
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  multi_az                    = false
  availability_zone           = "${var.AWS_REGION}a"
  db_subnet_group_name        = aws_db_subnet_group.subnet_group.name
  backup_retention_period     = 0
  db_name                     = var.aws_rds_db_name
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
  username                    = var.aws_rds_db_user
  password                    = random_string.rds_pass.result
  parameter_group_name        = "default.mysql8.0"
  skip_final_snapshot         = true
  publicly_accessible         = true
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
}

data "aws_db_instance" "rds" {
  db_instance_identifier = aws_db_instance.rds.id
}
