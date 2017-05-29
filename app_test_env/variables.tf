variable "tenancy_ocid" {

}
variable "user_ocid" {

}
variable "fingerprint" {

}
variable "private_key_path" {

}

variable "region" {
}

variable "customer" {
}

variable "identifier" {
  description = "Unique Identifier for Demo Environment"
}

variable "devops_key" {
  description = "Private Key path to access the server"
}

variable "bastion_key" {
  description = "Private Key path to access the server"
}

variable "manage_with_omc" {
}

variable "chef_key" {
  description = "Path to Private Key to access chef server"
}

variable "ad" {
  description = "AD to Deploy Application to"
}

variable "shape" {
  description = "Server size"
}

variable "compartment" {
  description = "Compartment to deploy to"
}
#BMC Tenancy Specific "OracleJamesCalise" Resource Lookup Values

variable "ssh_key" {
  type = "map"
  default = {
    jim = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0G5R0I21xfA0PyCFOI+TCRqSGtuEbAO9c7zRsE652jQ/LDGLS6uCL+U3eB4+e8FnnRF3A1IB9jPO7pLvhbL9nlD2PbOwqmWMp4W3a8xyjjHEcTaQ9Hc085GDtUki6hyW4+jtJ3GdK5Wp7liH438tND6EAdVeUcrt07/o99eKeDjtTd6R5AeL08JPW7OuEYLcYHH2ZkMyu795XuWAIQXeDMfbnLj6gcTgyftVZViGPoELO39Cl7g/JxVXsnNTCVtTa5CRRmaF/mKVcGuj+5fiTafx8CNh/6hkBm2hryBdTcSwGkiZgXs1GkOfmEEkk+61kNJbpHSo0FiBz1h4B91zD jamescalise@Jamess-MacBook-Pro.local"
  }
}

variable "image" {
  description = "BMC Image IDs"
  type = "map"
  default = {
    dev-base-managed    = "ocid1.image.oc1.phx.aaaaaaaavk63v6vpplr7mhy6khfbouzhslbailxcrsskxkwdraieetuvztaa"
    dev-base-image      = "ocid1.image.oc1.phx.aaaaaaaa5htpqshxdfhvtdoytd3dir4ckggskyhibphmlboxb3shlmlohfgq"
    custom_boot_image   = "ocid1.image.oc1.phx.aaaaaaaaxjval4zyfufn3f4wme6xuzmbsjd7zdftl37oituap3uxfomiwiea"
    ol-72               = "ocid1.image.oc1.phx.aaaaaaaaclseho77fcdfgejstt2bflkugcx5waa6bhconbokvhdp3qw7txlq"
    centos-72           = "ocid1.image.oc1.phx.aaaaaaaazt3sfrz2lfbha6okihvh4bwaufikhilhsek43hpvzxitl47nv2bq"
  }
}

variable "shapes" {
  description = "BMC Shape IDs"
  type = "map"
  default = {
    VM1      = "VM.Standard1.1"
    VM2      = "VM.Standard1.2"
    VM4      = "VM.Standard1.4"
    VM8      = "VM.Standard1.8"
    VM16     = "VM.Standard1.16"
    BM-STD   = "BM.Standard1.36"
    BM-HIGH  = "BM.HighIO1.36"
    BM-DENSE = "BM.DenseIO1.36"
  }
}

variable "compartments" {
  description = "Tenancy Compartments"
  type = "map"
  default = {
    demo               = "ocid1.compartment.oc1..aaaaaaaapj7xxlndxbcrmhw6cftylvdndmyetzmz2aanqy5vk3gciiro5hpa"
    sandbox            = "ocid1.compartment.oc1..aaaaaaaalnyvy5b33tsjwn6ajtlljbvcy7vqm6q33dqx53py46q476svu5ta"
    avitek_portal      = "ocid1.compartment.oc1..aaaaaaaaftmqjn7e3lx6lrmbtl4bohxwecwjv6udy5iphxaqt4uf7b2u32ma"
    network            = "ocid1.compartment.oc1..aaaaaaaazhpe4v2nmdokr6ngod5niyknyzqh67bolw5fttpg574a65dq5ida"
    image              = "ocid1.compartment.oc1..aaaaaaaajfwi2sxfcy6dwkyo7p6oyknyngnwdrketbyf7pxtudxdcizw7kwa"
    acme               = "ocid1.compartment.oc1..aaaaaaaamnyrvmydd6jehgik26hc4yxbm6bqdbcqkcnnkwsdq4rzsi5fvjja"
    avitek             = "ocid1.compartment.oc1..aaaaaaaanqzkyivdzo4lrtixomlekddctozq33zsog4iv4zjt5nvemnui7eq"
  }
}

