variable "AWS_SECRET_ACCESS_KEY" {
  type = string
}

variable "AWS_ACCESS_KEY_ID" {
  type = string
}

variable "DOCKER_REGISTRY_IMG" {
  type = string
}

variable "DOCKER_REGISTRY_USER" {
  type = string
}

variable "DOCKER_REGISTRY_PASS" {
  type = string
}

variable "AWS_REGION" {
  type = string
}

variable "aws_vpc_cidr" {
  description = "CIDR block for main"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_rds_db_name" {
  description = "The name of the mysql database."
  type        = string
  default     = "my_wordpress"
}

variable "aws_rds_db_user" {
  description = "The name of the mysql admin user."
  type        = string
  default     = "cywordpress_admin"
}