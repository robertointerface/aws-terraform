output "vpc_id" {
  value = aws_vpc.vpc_a1.id
}
output "public_subnet_a_id" {
  value = aws_subnet.public_subnet_A.id
}
output "public_subnet_b_id" {
  value = aws_subnet.public_subnet_B.id
}
output "private_subnet_a_id" {
  value = aws_subnet.private_subnet_a.id
}
output "private_subnet_b_id" {
  value = aws_subnet.private_subnet_b.id
}
output "security_group_id_for_load_balancer" {
  value = aws_security_group.load_balancer_SG.id
}
output "security_group_id_for_ec2_instances" {
  value = aws_security_group.ec2_instance_asg.id
}