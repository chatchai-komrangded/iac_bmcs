variable "compartment_name" {
 description = "Compartment to run server in"
}

variable "public_key" {
 description = "Public key to access the Server"
}

variable "ad_name" {
  description = "BMC Availability Domains"
}

variable "subnet_name" {
  description = "Network Subnets"
}

variable "shape_name" {
  description = "Server Shape"
}
variable "server_display_name" {
  description = "Server Name"
}

variable "hostname" {
  description = "Server Hostname"
}

variable "cloud_init_file" {
  description = "User provided Cloud Init"
  default = "/Users/jcalise/Projects/terraform/BMCS-Samples/modules/base/omc-config/test.yaml"
}

variable "manage_with_omc" {
  default = false
}


#OMC Configuration
variable "omc" {
  description = "Configure OMC Agent"
  default = {
    configure         = false
    private_key_path  = ""
    entity_file       = ""
    entity_creds_file = ""
  }
}

variable "devops_key" {
  description = "Devops User Key to access servers and configure"
  default = ""
}

variable "bastion" {
  description = "Access server through bastion"
  default = {
    host=""
    private_key_path=""
  }
}
