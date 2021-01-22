locals {
  tags = {
    Name        = var.application
    Application = var.application
    Owner       = var.owner
    Environment = var.environment
  }
}

data "aws_availability_zones" "this" {
  dynamic "filter" {
    for_each = var.az_filter == [] ? [] : [1]
    content {
      name   = "zone-name"
      values = var.az_filter
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  tags                 = local.tags
}

resource "aws_vpc_dhcp_options" "this" {
  domain_name         = var.dhcp_options_domain_name
  domain_name_servers = var.dhcp_options_domain_name_servers
  tags                = local.tags
}

resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this.id
}

resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.this.names)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, index(data.aws_availability_zones.this.names, data.aws_availability_zones.this.names[count.index]) + 10)
  availability_zone       = element(data.aws_availability_zones.this.names, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    {
      Name = format("${var.application}-public-%s", element(data.aws_availability_zones.this.names, count.index))
    }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = local.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.application}-public-rt" })
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  count = length(data.aws_availability_zones.this.names)

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  count = length(data.aws_availability_zones.this.names)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, index(data.aws_availability_zones.this.names, data.aws_availability_zones.this.names[count.index]))
  availability_zone = element(data.aws_availability_zones.this.names, count.index)

  tags = merge(
    local.tags,
    {
      Name = format("${var.application}-private-%s", element(data.aws_availability_zones.this.names, count.index))
    }
  )
}

resource "aws_eip" "this" {
  count = length(data.aws_availability_zones.this.names)

  vpc = true
  tags = merge(
    local.tags,
    {
      Name = format("${var.application}-ngw-eip-%s", element(data.aws_availability_zones.this.names, count.index))
    }
  )
}

resource "aws_nat_gateway" "this" {
  count = length(data.aws_availability_zones.this.names)

  allocation_id = element(aws_eip.this[*].id, count.index)
  subnet_id     = element(aws_subnet.public[*].id, count.index)

  tags = merge(
    local.tags,
    {
      Name = format("${var.application}-ngw-%s", element(data.aws_availability_zones.this.names, count.index))
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count = length(data.aws_availability_zones.this.names)

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.tags,
    {
      Name = format("${var.application}-private-rt-%s", element(data.aws_availability_zones.this.names, count.index))
    }
  )
}

resource "aws_route" "private" {
  count = length(data.aws_availability_zones.this.names)

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private" {
  count = length(data.aws_availability_zones.this.names)

  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, count.index)
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.region}.s3"
  tags         = local.tags
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.region}.dynamodb"
  tags         = local.tags
}
