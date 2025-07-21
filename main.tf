terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 4.0" }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# 1. VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "${var.environment}-vpc" }
}

# 2. Subnets
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.environment}-public-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = { Name = "${var.environment}-private-${count.index}" }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.environment}-igw" }
}

# 4. NAT Gateway + EIP
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "${var.environment}-nat-gw" }
}

# 5. Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.environment}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "${var.environment}-private-rt" }
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# 6a. Stateless Firewall Rule Group
resource "aws_networkfirewall_rule_group" "stateless" {
  name     = "${var.environment}-stateless"
  type     = "STATELESS"
  capacity = 100

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              protocols = [6]
              destination_port {
                from_port = 80
                to_port   = 80
              }
              destination_port {
                from_port = 443
                to_port   = 443
              }
            }
          }
        }
      }
    }
  }

  tags = { Name = "${var.environment}-stateless-rg" }
}

# 6b. Stateful Firewall Rule Group
resource "aws_networkfirewall_rule_group" "stateful" {
  name     = "${var.environment}-stateful"
  type     = "STATEFUL"
  capacity = 50

  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          protocol         = "IP"
          source           = "ANY"
          source_port      = "ANY"
          destination      = var.blocked_ip
          destination_port = "ANY"
          direction        = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["100"]
        }
      }
    }
  }

  tags = { Name = "${var.environment}-stateful-rg" }
}

# 6c. Firewall Policy
resource "aws_networkfirewall_firewall_policy" "policy" {
  name = "${var.environment}-fw-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateless.arn
      priority     = 10
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful.arn
    }
  }

  tags = { Name = "${var.environment}-fw-policy" }
}

# 6d. Deploy Firewall to Private Subnets
resource "aws_networkfirewall_firewall" "fw" {
  name                = "${var.environment}-fw"
  vpc_id              = aws_vpc.main.id
  firewall_policy_arn = aws_networkfirewall_firewall_policy.policy.arn

  dynamic "subnet_mapping" {
    for_each = aws_subnet.private
    content {
      subnet_id = subnet_mapping.value.id
    }
  }

  tags = { Name = "${var.environment}-fw" }
}

# Outputs
output "vpc_id"             { value = aws_vpc.main.id }
output "public_subnet_ids"  { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "firewall_arn"       { value = aws_networkfirewall_firewall.fw.arn }
