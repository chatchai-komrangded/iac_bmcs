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

variable "cloud_init_file" {
  description = "User provided Cloud Init"
  default = ""
}

#OMC Configuration
variable "omc" {
  description = "Configure OMC Agent"
  default = {
    configure         = "no"
    omc_key           = ""
    private_key_path  = ""
    entity_file       = ""
    entity_creds_file = ""
  }
}

variable "bastion" {
  description = "Access server through bastion"
  default = {
    host=""
    private_key_path=""
  }
}
