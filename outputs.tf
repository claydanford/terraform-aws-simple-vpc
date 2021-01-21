output "private_subnets" {
  value = aws_subnet.private
}

output "public_subnets" {
  value = aws_subnet.public
}

output "vpc" {
  value = aws_vpc.this
}
