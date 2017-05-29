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

variable "hostname" {
  description = "Server Hostname"
}
