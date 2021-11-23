variable "tags" {
  type = map
  default = { Name = "test-graphstore" }
}

variable "region" {
  default = "us-east-1"
}

variable eip_alloc_id {
  default = "eipalloc-06ca9adfa0978aab9"
}

variable "instance_type" {
  default = "t2.large" 
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "ssh server port"
}

variable "http_port" {
  type        = number
  default     = 80
  description = "graphstore server port"
}
