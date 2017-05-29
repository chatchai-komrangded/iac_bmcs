variable "image" {
  description = "BMC Image IDs"

  default = {
    custom-boot-image   = "ocid1.image.oc1.phx.aaaaaaaaxjval4zyfufn3f4wme6xuzmbsjd7zdftl37oituap3uxfomiwiea"
    dev-base-image      = "ocid1.image.oc1.phx.aaaaaaaa5htpqshxdfhvtdoytd3dir4ckggskyhibphmlboxb3shlmlohfgq"
    ol-72               = "ocid1.image.oc1.phx.aaaaaaaaclseho77fcdfgejstt2bflkugcx5waa6bhconbokvhdp3qw7txlq"
  }
}

variable "shape" {
  description = "BMC Shape IDs"

  default = {
    VM1      = "VM.Standard1.1"
    VM2      = "VM.Standard1.2"
    VM4      = "VM.Standard1.4"
    VM8      = "VM.Standard1.8"
    VM16     = "VM.Standard1.16"
    BM-STD   = "BM.Standard1.36"
    BM-HIGH  = "BM.High1.36"
    BM-DENSE = "BM.Dense1.36"
  }
}

variable "ad" {
  description = "BMC Availability Domains"

  default = {
    ad-0      = "YZAF:PHX-AD-1"
    ad-1      = "YZAF:PHX-AD-2"
    ad-2      = "YZAF:PHX-AD-3"
  }
}

variable "compartments" {
  description = "Tenancy Compartments"

  default = {
    demo               = "ocid1.compartment.oc1..aaaaaaaapj7xxlndxbcrmhw6cftylvdndmyetzmz2aanqy5vk3gciiro5hpa"
    avitek_portal      = "ocid1.compartment.oc1..aaaaaaaaftmqjn7e3lx6lrmbtl4bohxwecwjv6udy5iphxaqt4uf7b2u32ma"
    network            = "ocid1.compartment.oc1..aaaaaaaazhpe4v2nmdokr6ngod5niyknyzqh67bolw5fttpg574a65dq5ida"
    image              = "ocid1.compartment.oc1..aaaaaaaajfwi2sxfcy6dwkyo7p6oyknyngnwdrketbyf7pxtudxdcizw7kwa"
  }
}

variable "ssh_key" {
 default = {
    jim = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0G5R0I21xfA0PyCFOI+TCRqSGtuEbAO9c7zRsE652jQ/LDGLS6uCL+U3eB4+e8FnnRF3A1IB9jPO7pLvhbL9nlD2PbOwqmWMp4W3a8xyjjHEcTaQ9Hc085GDtUki6hyW4+jtJ3GdK5Wp7liH438tND6EAdVeUcrt07/o99eKeDjtTd6R5AeL08JPW7OuEYLcYHH2ZkMyu795XuWAIQXeDMfbnLj6gcTgyftVZViGPoELO39Cl7g/JxVXsnNTCVtTa5CRRmaF/mKVcGuj+5fiTafx8CNh/6hkBm2hryBdTcSwGkiZgXs1GkOfmEEkk+61kNJbpHSo0FiBz1h4B91zD jamescalise@Jamess-MacBook-Pro.local"
    jenkins = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEArn21PGy1SZ6AYFlztFUL1gv63EXMbSb4qo1SzPAwZgcQXjciU8YsettV81YIFzvIedEn4mhD8ebGKK1k8oYB7HYNsSywbXmqisI+75xY37EZT6ah+cxENmVxmzpOjOYH31wj792tf/WpUUpnN8MdIlTW8uAWNIa6Mz9YhAZ0sJILDOlSNr/rorrGYyYLBtJqbVAZlwEfUSgQTkMwBWK4L7aXOLMDFFAi2oEqsjmT3rWX55YzrwXIMvNXjslen6gXqrdoCeakKMbQ788fQqb1P9hgsmHhkERJfwhgFy+R1RUfPMHdZG7P2vNLUZDd54ROCmj2F852HkertpDMFNMWrQ== oracle@oraclelinux6.localdomain"
   }
}

variable "identifier" {
  description = "Unique Identifier for Demo Environment"
  default = "PHX"
}

variable "server1_name" {
  default = "hol-server-1"
}

variable "server2_name" {
  default = "hol-server-2"
}
