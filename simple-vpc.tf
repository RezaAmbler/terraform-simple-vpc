#data "terraform_remote_state" "network" {
#  backend = "s3"
#
#  config {
#    bucket = "reza-terraform-state"
#    key    = "network/terraform.tfstate"
#    region = "us-west-2"
#  }
#}

# BEGIN VARIABLES
# Variables to be used through the TF file
# These can also be defined in another file and passed into
# the terraform file for consumption

#DATA
data "aws_availability_zones" "all" {}

data "aws_ami" "bastion_ami" {
  most_recent = true

  filter {
    name   = "tag:Build_Type"
    values = ["simple_vpc_bastion"]
  }
}

data "aws_ami" "webapp_ami" {
  most_recent = true

  filter {
    name   = "tag:Build_Type"
    values = ["simple_vpc_webapp"]
  }
}

# USER DEFINED
variable "aws_region" {
  description = "EC2 Region for the VPC"
  default     = "us-east-1"
}

variable "az01" {
  default = "us-east-1a"
}

variable "az02" {
  default = "us-east-1b"
}

variable "az03" {
  default = "us-east-1c"
}

variable "ssh_key_pair" {
  description = "SSH Key Pair to be used for EC2"
}

variable "http_server_port" {
  description = "http web server listener port"
  default     = "80"
}

# END USER DEFINED

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default     = "192.168.200.0/24"
}

variable "public_subnet_cidr_01" {
  description = "CIDR for the Public Subnet"
  default     = "192.168.200.0/26"
}

variable "public_subnet_cidr_02" {
  description = "CIDR for the Public Subnet"
  default     = "192.168.200.64/26"
}

variable "private_subnet_cidr_01" {
  description = "CIDR for the Private Subnet"
  default     = "192.168.200.128/26"
}

variable "private_subnet_cidr_02" {
  description = "CIDR for the Private Subnet"
  default     = "192.168.200.192/26"
}

variable "aws_profile" {
  description = "AWS profile to use"
}

variable "db_password" {
  description = "Database password"
}

# END VARIABLES

# Define the provider, this can be one of a long list of Cloud providers
# AWS , Azure, GCP, VMWare, etc..
# list here : https://www.terraform.io/docs/providers/
provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# Here we have multiple resource blocks. 
# This is where the rubber meets the road, and we actually 
# start deploying resources into the Cloud Provider (AWS)
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  #main_route_table     = "${aws_route_table.az-01-public.id}"

  tags {
    Name    = "VPC TEST"
    Project = "PROJ007"
    BU      = "PU"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name    = "aws_internet_gateway"
    Project = "PROJ007"
    BU      = "PU"
  }
}

resource "aws_security_group" "nat_sg" {
  name        = "test_vpc_nat"
  description = "a test nat gateway for the private subnet"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name    = "Test NAT SG"
    Project = "PROJ007"
    BU      = "PU"
  }
}

# EIP needed for the NAT Gateway
resource "aws_eip" "ngw-eip" {
  vpc = true

  tags {
    Name    = "ngw-eip"
    Project = "PROJ007"
    BU      = "PU"
  }

  # VPC ID ?
}

# //implement NAT Gateway here, not the example's nat instance (deprecated)

resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.ngw-eip.id}"
  subnet_id     = "${aws_subnet.az-01-public.id}"

  tags {
    Name    = "ngw"
    Project = "PROJ007"
    BU      = "PU"
  }
}

# "us-west-2a-public" 
# Subnet definition, calling a variable from the begining
resource "aws_subnet" "az-01-public" {
  # VPC ID taken from the terraform state file
  # This ID is only available once Terraform has made the VPC
  # Terraform handles the event ordering
  vpc_id = "${aws_vpc.vpc.id}"

  # variable defined at the top
  cidr_block        = "${var.public_subnet_cidr_01}"
  availability_zone = "${var.az01}"

  tags {
    Name    = "Public Subnet AZ01"
    Project = "PROJ007"
    BU      = "PU"
  }
}

# Create a Route Table, assign it to the VPC ID
# use a better name for the RT since it's not AZ specific
resource "aws_route_table" "az-01-public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name    = "Public Subnet"
    Project = "PROJ007"
    BU      = "PU"
  }
}

# Here we associate the Subnet from above with the reoute table above
# Subnet : us-west-2a-public 
# Route T: us-west-2a-public
resource "aws_route_table_association" "az-01-public" {
  subnet_id      = "${aws_subnet.az-01-public.id}"
  route_table_id = "${aws_route_table.az-01-public.id}"
}

# Public Subnet #2
resource "aws_subnet" "az-02-public" {
  vpc_id = "${aws_vpc.vpc.id}"

  cidr_block        = "${var.public_subnet_cidr_02}"
  availability_zone = "${var.az02}"

  tags {
    Name    = "Public Subnet AZ02"
    Project = "PROJ007"
    BU      = "PU"
  }
}

resource "aws_route_table_association" "az-02-public" {
  subnet_id      = "${aws_subnet.az-02-public.id}"
  route_table_id = "${aws_route_table.az-01-public.id}"

  # better name for the route table, not az specific
}

# END Public Subnet

# us-west-2a-private
# Private Subnet
resource "aws_subnet" "az-01-private" {
  vpc_id = "${aws_vpc.vpc.id}"

  cidr_block        = "${var.private_subnet_cidr_01}"
  availability_zone = "${var.az01}"

  tags {
    Name    = "Private Subnet AZ01"
    Project = "PROJ007"
    BU      = "PU"
  }
}

resource "aws_subnet" "az-02-private" {
  vpc_id = "${aws_vpc.vpc.id}"

  cidr_block = "${var.private_subnet_cidr_02}"

  availability_zone = "${var.az02}"

  tags {
    Name    = "Private Subnet AZ02"
    Project = "PROJ007"
    BU      = "PU"
  }
}

# Route table for private subnet
resource "aws_route_table" "az-01-private" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.ngw.id}"
  }

  tags {
    Name    = "Private Subnet"
    Project = "PROJ007"
    BU      = "PU"
  }
}

# Associate the Subnet and Route Table together
# Subnet : us-west-2a-private
# Route T: us-west-2a-private
# Obviously we would have better / more generic names for some of these
# This is just a quick example
resource "aws_route_table_association" "az-01-private" {
  subnet_id      = "${aws_subnet.az-01-private.id}"
  route_table_id = "${aws_route_table.az-01-private.id}"
}

resource "aws_route_table_association" "az-02-private-rtb" {
  subnet_id      = "${aws_subnet.az-02-private.id}"
  route_table_id = "${aws_route_table.az-01-private.id}"
}

# END VPC
# BEGIN INSTANCES
#BASTION

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-host-sg"
  description = "bastion host aws_security_group"
  vpc_id      = "${aws_vpc.vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name    = "Bastion SG"
    Project = "PROJ007"
    BU      = "PU"
  }
}

resource "aws_eip" "bastion_eip" {
  vpc = true

  #instance = "${aws_instance.proj007_instance.id}"
  tags {
    Name    = "Test Public Subnet"
    Project = "PROJ007"
    BU      = "PU"
  }
}

resource "aws_eip_association" "bastion_eip" {
  instance_id   = "${aws_instance.bastion.id}"
  allocation_id = "${aws_eip.bastion_eip.id}"
}

resource "aws_instance" "bastion" {
  ami               = "${data.aws_ami.bastion_ami.id}"
  instance_type     = "t2.nano"
  availability_zone = "${var.az01}"
  subnet_id         = "${aws_subnet.az-01-public.id}"

  # NOTE : https://github.com/hashicorp/terraform/issues/7221#issuecomment-227156871
  #security_groups = [
  #  "${aws_security_group.bastion_sg.id}",
  #]

  vpc_security_group_ids = [
    "${aws_security_group.bastion_sg.id}",
  ]
  #key_name = "Reza-East-1"
  key_name = "${var.ssh_key_pair}"
  tags {
    Name    = "ec2_bastion_example"
    Project = "PROJ007"
    BU      = "PU"
  }
}

# END BASTION

# WEB APP 1

resource "aws_security_group" "web-app-sg" {
  name        = "web-app-sg"
  description = "Web App Server Security Group"
  vpc_id      = "${aws_vpc.vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    /*
    security_groups = [
      "${aws_security_group.bastion_sg.id}",
    ]
    */
  }

  tags {
    Name    = "WEB APP NAT SG"
    Project = "PROJ007"
    BU      = "PU"
  }
}

resource "aws_instance" "webapp01" {
  ami                         = "${data.aws_ami.webapp_ami.id}"
  instance_type               = "t2.nano"
  availability_zone           = "${var.az01}"
  subnet_id                   = "${aws_subnet.az-01-private.id}"
  associate_public_ip_address = false

  vpc_security_group_ids = [
    "${aws_security_group.web-app-sg.id}",
  ]

  ebs_block_device = {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = true
    encrypted             = true
    device_name           = "/dev/sdb"
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
    #!/bin/bash
    /usr/bin/curl http://169.254.169.254/latest/meta-data/instance-id/ | sudo tee /var/www/html/index.html
    sudo /usr/sbin/parted /dev/sdb mklabel gpt
    sudo /usr/sbin/parted -a opt /dev/sdb mkpart primary ext4 0% 100%
    sudo /usr/sbin/mkfs.ext4 -L datapartition /dev/sdb1
    sudo /usr/bin/mkdir /opt/foo
    sudo /usr/bin/mount /dev/sdb1 /opt/foo
    /usr/bin/curl http://169.254.169.254/latest/meta-data/instance-id/ | sudo tee /opt/foo/instance-id.txt
    EOF

  #key_name = "Reza-East-1"
  key_name = "${var.ssh_key_pair}"

  tags {
    Name    = "WEB APP 01"
    Project = "PROJ007"
    BU      = "PU"
  }
}

# END WEB APP 1

# WEB APP 2
resource "aws_instance" "webapp02" {
  ami                         = "${data.aws_ami.webapp_ami.id}"
  instance_type               = "t2.nano"
  availability_zone           = "${var.az02}"
  subnet_id                   = "${aws_subnet.az-02-private.id}"
  associate_public_ip_address = false

  vpc_security_group_ids = [
    "${aws_security_group.web-app-sg.id}",
  ]

  user_data = <<-EOF
    #!/bin/bash
    curl http://169.254.169.254/latest/meta-data/instance-id/ | sudo tee /var/www/html/index.html
    EOF

  #key_name = "Reza-East-1"
  key_name = "${var.ssh_key_pair}"

  tags {
    Name    = "WEB APP 02"
    Project = "PROJ007"
    BU      = "PU"
  }
}

# END WEB APP 2
# END INSTANCES

# RDS INSTANCE 

resource "aws_db_instance" "rds" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "RDSDBTEST"
  username             = "foo"
  password             = "${var.db_password}"
  parameter_group_name = "default.mysql5.7"
  availability_zone    = "${var.az01}"

  tags {
    Name    = "WEB APP 02"
    Project = "PROJ007"
    BU      = "PU"
  }
}

resource "aws_elb" "elb" {
  # END RDS INSTANCE

  # Classic ELB method
  name = "terraform-elb-example"

  #availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.elb_sg.id}"]
  subnets         = ["${aws_subnet.az-01-public.id}", "${aws_subnet.az-02-public.id}"]

  cross_zone_load_balancing = true

  instances = [
    "${aws_instance.webapp01.id}",
    "${aws_instance.webapp02.id}",
  ]

  # Alternate method : https://www.terraform.io/docs/providers/aws/r/elb_attachment.html

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.http_server_port}/"
  }
  tags {
    Name    = "WEB ELB"
    Project = "PROJ007"
    BU      = "PU"
  }
}

resource "aws_security_group" "elb_sg" {
  name   = "terraform-elb-example-sg"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = "${var.http_server_port}"
    to_port     = "${var.http_server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name    = "WEB ELB SG"
    Project = "PROJ007"
    BU      = "PU"
  }
}

# This presents nice output to the user / consumer once
# terraform has finished the job and has all the state information
output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${aws_vpc.vpc.id}"
}

output "bastion_eip_ip" {
  value = "${aws_eip.bastion_eip.public_ip}"
}

output "webapp01_private_ip" {
  value = "${aws_instance.webapp01.private_ip}"
}

output "webapp02_private_ip" {
  value = "${aws_instance.webapp02.private_ip}"
}

output "elb_dns_name" {
  value = "${aws_elb.elb.dns_name}"
}

output "aws_rds_instance_id" {
  value = "${aws_db_instance.rds.id}"
}

output "aws_rds_endpoint" {
  value = "${aws_db_instance.rds.endpoint}"
}
