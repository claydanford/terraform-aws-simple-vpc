variable "application" {
  description = "The application to be used to name all resources."
  type        = string
  default     = "foo"
}

variable "az_filter" {
  description = "AZ's to filter out of making subnets."
  type        = list(string)
  default     = []
}

variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.255.0.0/16"
}

variable "dhcp_options_domain_name" {
  description = "Specifies DNS name for DHCP options set (requires enable_dhcp_options set to true)"
  type        = string
  default     = "foo.bar"
}

variable "dhcp_options_domain_name_servers" {
  description = "Specify a list of DNS server addresses for DHCP options set, default to AWS provided (requires enable_dhcp_options set to true)"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "environment" {
  description = "Environment for this infrastructure. Suggested to use terraform.workspace"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of this infrastructure"
  type        = string
  default     = "admin"
}

variable "region" {
  description = "Region to deploy this infrastructure"
  type        = string
  default     = "us-west-2"
}
