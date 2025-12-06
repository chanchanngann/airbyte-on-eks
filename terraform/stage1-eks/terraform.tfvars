name_prefix = "airbyte"

region = ""

vpc_cidr = "10.0.0.0/16"

public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

azs = ["", "", ""]

cluster_name = "airbyte-cluster"

admin_principal_arn = "arn:aws:iam::xxxxxxxxxxxxx:user/yyy"

cluster_iam_role_name = "airbyte-cluster-role"

ec2_key_name = ""

my_ip_cidr = "xx.xx.xx.xx/24"