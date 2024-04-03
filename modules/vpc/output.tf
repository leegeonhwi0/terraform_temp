output "def_vpc_id" {
  value = aws_vpc.def_vpc.id
}

output "private_sub_a_ids" {
  value = aws_subnet.pvt_a[*].id
}

output "private_sub_c_ids" {
  value = aws_subnet.pvt_c[*].id
}

output "public_sub_ids" {
  value = [aws_subnet.pub_a.id, aws_subnet.pub_c.id]
}


