variable "region" {}
variable "azs" { type = list(any) }
variable "main-vpc-cidr" {}
variable "public-subnets-cidr" { type = list(any) }
variable "private-subnets-cidr" { type = list(any) }
