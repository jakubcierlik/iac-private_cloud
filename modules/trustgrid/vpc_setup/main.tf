resource "aws_key_pair" "cust_key_pair" {
  key_name   = "${var.customer_name}-${var.aws_region}-key"
  public_key = var.public_key
  tags       = merge(var.tags, { Name = "${var.customer_name}-ckp" })
}

# --------------------------------------------------- VPC & Subnets ---------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true" # Gives you an internal domain name
  enable_dns_hostnames = "true" # Gives you an internal host name
  enable_classiclink   = "false"
  instance_tenancy     = "default"
  tags                 = merge(var.tags, {
    Name = "${var.customer_name}-vpc",
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.customer_name}-igw" })
}

resource "aws_subnet" "public_01" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.primary_az
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" // it makes this a public subnet
  tags                    = merge(var.tags, { Name = "${var.customer_name}-subnet-public-01" })
}

resource "aws_subnet" "public_02" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.secondary_az
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true" // it makes this a public subnet
  tags                    = merge(var.tags, { Name = "${var.customer_name}-subnet-public-02" })
}

resource "aws_subnet" "private_01" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.primary_az
  cidr_block              = "10.0.11.0/24"
  map_public_ip_on_launch = "false" // it makes this a private subnet
  tags                    = merge(var.tags, { Name = "${var.customer_name}-subnet-private-01" })
}

resource "aws_subnet" "private_02" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.secondary_az
  cidr_block              = "10.0.12.0/24"
  map_public_ip_on_launch = "false" // it makes this a private subnet
  tags                    = merge(var.tags, { Name = "${var.customer_name}-subnet-private-02" })
}

# ---------------------------------------------------- Route Tables ----------------------------------------------------

# Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(var.tags, { Name = "${var.customer_name}-public-route-table" })
}

resource "aws_route_table_association" "public_to_subnet_01" {
  subnet_id      = aws_subnet.public_01.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_to_subnet_02" {
  subnet_id      = aws_subnet.public_02.id
  route_table_id = aws_route_table.public.id
}

# Private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(var.tags, { Name = "${var.customer_name}-private-route-table" })
}

resource "aws_route_table_association" "private_to_subnet_01" {
  subnet_id      = aws_subnet.private_01.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_to_subnet_02" {
  subnet_id      = aws_subnet.private_02.id
  route_table_id = aws_route_table.private.id
}

# -------------------------------------------------- Security Groups --------------------------------------------------

# Attached to load balancers
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = -1
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.customer_name}-default-sg" })
}

locals {
  traffic_rules = {

#    "gateway_data_ingress" : [
#      {
#        description : "SSL",
#        from_port : 8443, to_port : 8443, protocol : "tcp", cidr_blocks : ["0.0.0.0/0"]
#      },
#      {
#        description : "SSL",
#        from_port : 8443, to_port : 8443, protocol : "udp", cidr_blocks : ["0.0.0.0/0"]
#      },
#      {
#        description : "HTTPS",
#        from_port : 443, to_port : 443, protocol : "tcp", cidr_blocks : ["0.0.0.0/0"]
#      },
#      {
#        description : "Wireguard",
#        from_port : 51820, to_port : 51820, protocol : "udp", cidr_blocks : ["0.0.0.0/0"]
#      },
#    ],

    "gateway_mgmt_ingress" : [
      {
        description : "App load balancer",
        from_port : 80, to_port : 80, protocol : "tcp", cidr_blocks : [aws_vpc.main.cidr_block]
      },
      {
        description : "Wireguard load balancer",
        from_port : 9000, to_port : 9000, protocol : "tcp", cidr_blocks : [aws_vpc.main.cidr_block]
      },
      {
        description : "Wireguard load balancer",
        from_port : 9001, to_port : 9001, protocol : "tcp", cidr_blocks : [aws_vpc.main.cidr_block]
      },
      {
        description : "SSL",
        from_port : 8443, to_port : 8443, protocol : "tcp", cidr_blocks : ["0.0.0.0/0"]
      },
      {
        description : "SSL",
        from_port : 8443, to_port : 8443, protocol : "udp", cidr_blocks : ["0.0.0.0/0"]
      },
      {
        description : "HTTPS",
        from_port : 443, to_port : 443, protocol : "tcp", cidr_blocks : ["0.0.0.0/0"]
      },
      {
        description : "Wireguard",
        from_port : 51820, to_port : 51820, protocol : "udp", cidr_blocks : ["0.0.0.0/0"]
      },
    ]
  }
}

# Attach to management interface of gateway EC2 nodes
resource "aws_security_group" "gateway_mgmt" {
  vpc_id = aws_vpc.main.id
  name   = "${var.customer_name}-gateway-mgmt"

  dynamic "ingress" {
    for_each = local.traffic_rules.gateway_mgmt_ingress
    content {
      description = lookup(ingress.value, "description", null)
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.customer_name}-gateway-mgmt" })
}

# Attach to data interface of gateway EC2 nodes
resource "aws_security_group" "gateway_data" {
  vpc_id = aws_vpc.main.id
  name   = "${var.customer_name}-gateway-data"

#  dynamic "ingress" {
#    for_each = local.traffic_rules.gateway_data_ingress
#    content {
#      description = lookup(ingress.value, "description", null)
#      from_port   = ingress.value["from_port"]
#      to_port     = ingress.value["to_port"]
#      protocol    = ingress.value["protocol"]
#      cidr_blocks = ingress.value["cidr_blocks"]
#
#    }
#  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.customer_name}-gateway-data" })
}