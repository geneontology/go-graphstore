variable "tags" {
  type = map
  default = { Name = "test-graphstore" }
}

variable "instance_type" {
  default = "t2.large"
}

variable "disk_size" {
  default = 100
  description = "size of disk in Gigabytes"
}

variable "public_key_path" {
  default = "/tmp/go-ssh.pub"
}

variable "open_ports" {
  type = list 
  default = [22, 80, 443]
}

variable "use_elastic_ip" {
  type = bool
  description = "whether to use an elastic ip or not"
  default = true
}

provider "aws" {
  region = "us-east-1"
  shared_credentials_files = [ "/tmp/go-aws-credentials" ]
  profile = "default"
}

// optional will be created if value is not an menty string
variable "dns_record_name" {
  type = string
  description = "type A DNS record wich will be mapped to public ip"
  default = ""
}

variable "dns_zone_id" {
  type = string
  description = "zone id for dns record."
  default = ""
}

module "base" {
  source = "git::https://github.com/geneontology/devops-aws-go-instance.git?ref=V3.1"
  instance_type = var.instance_type
  public_key_path = var.public_key_path
  dns_record_name = var.dns_record_name
  dns_zone_id = var.dns_zone_id
  use_elastic_ip = var.use_elastic_ip
  tags = var.tags
  open_ports = var.open_ports
  disk_size = var.disk_size
}

output "dns_records" {
  value = module.base.dns_records
}

output "public_ip" {
   value                  = module.base.public_ip
}
