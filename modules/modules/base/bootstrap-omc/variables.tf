variable "compartment_name" {
 description = "Compartment to run server in"
}

variable "public_key" {
 description = "Public key to access the Server"
}

variable "image_name" {
  description = "BMC Image IDs"
}

variable "shape_name" {
  description = "BMC Shape IDs"
}

variable "ad_name" {
  description = "BMC Availability Domains"
}

variable "subnet_name" {
  description = "Network Subnets"
}

variable "server_display_name" {
  description = "Server Name"
}

variable "custom_image_name" {
}

variable "custom_image_compartment" {
}

variable "devops_key" {
  description = "Devops User Key to access servers and configure"
  default = ""
}

variable "bastion_host" {
  description = "Access server through bastion"
}

variable "bastion_private_key_path" {
  description = "Access server through bastion"
}
