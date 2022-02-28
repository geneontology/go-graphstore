output "public_ip" {
  value = aws_eip.graphstore_eip.public_ip
}
