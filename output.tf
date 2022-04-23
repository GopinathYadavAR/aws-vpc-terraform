output "vpc_id" {
  description = "The ID of the my eks VPC"
  value       = aws_vpc.my-eks-vpc.id

}
output "public-subnet-id" {
  description = "The ID of the public subnets"
  value       = aws_subnet.my-eks-public-subnets

}
output "private-subnet-id" {
  description = "The ID of the private subnets"
  value       = aws_subnet.my-eks-private-subnets

}
