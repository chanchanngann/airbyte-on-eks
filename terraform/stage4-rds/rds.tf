####################################
# Subnet group for RDS (private subnets)
####################################

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "postgres-subnet-group"
  subnet_ids = data.terraform_remote_state.stage1.outputs.private_subnets
  tags = {
    Name = "${var.name_prefix}-rds-subnet-group"
  }
}

###################################
# Security group for RDS
###################################

resource "aws_security_group" "rds_sg" {
  vpc_id = data.terraform_remote_state.stage1.outputs.vpc_id

  ingress {
    description = "Allow Bastion to RDS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    security_groups = [data.terraform_remote_state.stage3.outputs.bastion_security_group_id]
  }

  ingress {
    description     = "Allow Airbyte to RDS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.stage1.outputs.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

###################################
# RDS Instance
###################################
resource "aws_db_instance" "airbyte_config_postgres" {
  identifier             = "${var.name_prefix}-config-postgres"
  engine                 = "postgres"
  engine_version         = "16.9" # Pick stable version supported by Airbyte
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  db_name                = var.config_db
  username               = var.config_db_username
  password               = var.config_db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true # RDS is dropped immediately, no snapshot retained.
  publicly_accessible    = false
  # storage_encrypted       = true
  backup_retention_period = 1
  parameter_group_name    = aws_db_parameter_group.rds_pg_for_config.name # An SSL workaround

  tags = {
    Name = "${var.name_prefix}-config-postgres"
  }
}

resource "aws_db_instance" "cdc_source_postgres" {
  identifier             = "${var.name_prefix}-cdc-source-postgres"
  engine                 = "postgres"
  engine_version         = "16.9" # Pick stable version supported by Airbyte
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  db_name                = var.cdc_db
  username               = var.cdc_db_username
  password               = var.cdc_db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true # RDS is dropped immediately, no snapshot retained.
  publicly_accessible    = false
  # storage_encrypted       = true
  backup_retention_period = 1
  parameter_group_name    = aws_db_parameter_group.rds_pg_for_cdc.name # to enable logical replication

  tags = {
    Name = "${var.name_prefix}-cdc-postgres"
  }
}


###################################
# RDS parameter group
###################################

resource "aws_db_parameter_group" "rds_pg_for_config" {

  name   = "rds-airbyte-pg"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = 0 # Required for Airbyte's Temporal service to connect
  }

}

resource "aws_db_parameter_group" "rds_pg_for_cdc" {

  name   = "rds-airbyte-pg-for-cdc"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl" # this is dynamic parameter, can be applied immediately.
    value = 0 
  }

  # parameter {
  #   name         = "wal_level"
  #   value        = "logical"
  #   apply_method = "pending-reboot"
  # }

  parameter {
    name  = "rds.logical_replication"
    value = 1
    apply_method = "pending-reboot" # this is static parameter, which requires DB reboot (not immediately).
  }


  # maximum amount of WALs that replication slots can retain.
  parameter {
    name  = "max_slot_wal_keep_size" # this is dynamic parameter, can be applied immediately.
    value = 4096
  }

  # at least 1
  # parameter {
  #   name  = "max_replication_slots"
  #   value = "5"
  # }

  # at least 1
  # parameter {
  #   name  = "max_wal_senders"
  #   value = "1"
  # }
}