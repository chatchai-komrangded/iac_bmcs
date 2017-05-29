provider "baremetal" {
  tenancy_ocid         = "${var.tenancy_ocid}"
  user_ocid            = "${var.user_ocid}"
  fingerprint          = "${var.fingerprint}"
  private_key_path     = "${var.private_key_path}"
}

data "baremetal_identity_availability_domains" "ads" {
  compartment_id = "${var.tenancy_ocid}"
}

resource "baremetal_core_virtual_network" "vcn" {
  cidr_block = "10.0.0.0/16"
  compartment_id = "${lookup(var.compartments,"network")}"
  display_name = "${var.identifier}-lbtest-Network"
  dns_label = "tomcat"
}

resource "baremetal_core_internet_gateway" "internet-gateway" {
    compartment_id =  "${lookup(var.compartments,"network")}"
    display_name = "Public-IG"
    vcn_id = "${baremetal_core_virtual_network.vcn.id}"
}

resource "baremetal_core_route_table" "route-table" {
    compartment_id = "${lookup(var.compartments,"network")}"
    vcn_id = "${baremetal_core_virtual_network.vcn.id}"
    display_name = "Public-RT"
    route_rules {
        cidr_block = "0.0.0.0/0"
        network_entity_id = "${baremetal_core_internet_gateway.internet-gateway.0.id}"
    }
}


resource "baremetal_core_security_list" "lb-sl" {
  compartment_id ="${lookup(var.compartments,"network")}"
  display_name = "APP-SL"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol = "6"
  }
  ingress_security_rules =
  [{
    tcp_options {
      max = "8080"
      min = "8080"
    }
    protocol = "6"
    source= "0.0.0.0/0"
  }]
}

resource "baremetal_core_subnet" "lb-subnet-1" {
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[0],"name")}"
  cidr_block = "${cidrsubnet("10.0.2.0/24",4,0)}"
  display_name = "LB-AD1"
  dns_label = "lb1"
  compartment_id = "${lookup(var.compartments,"network")}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.lb-sl.id}"]
  # FIXME: workaround for race condition in API
  provisioner "local-exec"  {
    command = "sleep 10"
  }
}

resource "baremetal_core_subnet" "lb-subnet-2" {
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[1],"name")}"
  cidr_block = "${cidrsubnet("10.0.2.0/24",4,1)}"
  display_name = "LB-AD2"
  dns_label = "lb2"
  compartment_id = "${lookup(var.compartments,"network")}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.lb-sl.id}"]
  # FIXME: workaround for race condition in API
  provisioner "local-exec"  {
    command = "sleep 10"
  }
}

resource "baremetal_load_balancer" "test-lb" {
  shape          = "100Mbps"
  compartment_id ="${lookup(var.compartments,"network")}"
  subnet_ids     = ["${baremetal_core_subnet.lb-subnet-1.id}","${baremetal_core_subnet.lb-subnet-2.id}"]
  display_name   = "${var.identifier}-test-LB"
}


resource "baremetal_core_dhcp_options" "app1-dhcp" {
  compartment_id = "${lookup(var.compartments,"network")}"
  display_name = "app-dhcp"
  options {
    type = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
  options {
    type = "SearchDomain"
    search_domain_names = ["app1.tomcat.oraclevcn.com"]
  }
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
}


resource "baremetal_core_security_list" "app-sl" {
    compartment_id ="${lookup(var.compartments,"network")}"
    display_name = "APP-SL"
    vcn_id = "${baremetal_core_virtual_network.vcn.id}"
    egress_security_rules {
        destination = "0.0.0.0/0"
        protocol = "6"
    }
    ingress_security_rules =
    [{
      tcp_options {
          max = "8080"
          min = "8080"
      }
      protocol = "6"
      source= "0.0.0.0/0"
    },
    {
      tcp_options {
          max = "22"
          min = "22"
      }
      protocol = "6"
      source= "10.0.1.0/24"
    }]
}

resource "baremetal_core_subnet" "app-subnet-1" {
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[0],"name")}"
  cidr_block = "${cidrsubnet("10.0.3.0/24",4,0)}"
  display_name = "APP"
  dns_label = "app"
  compartment_id = "${lookup(var.compartments,"network")}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.app-sl.id}"]
  dhcp_options_id = "${baremetal_core_dhcp_options.app1-dhcp.id}"

  # FIXME: workaround for race condition in API
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "baremetal_core_instance" "standard-server" {
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[0],"name")}"
  compartment_id = "${lookup(var.compartments,"demo")}"
  display_name = "S1"
  image = "ocid1.image.oc1.phx.aaaaaaaaclseho77fcdfgejstt2bflkugcx5waa6bhconbokvhdp3qw7txlq"
  shape = "${lookup(var.shape, "VM2")}"
  subnet_id = "${baremetal_core_subnet.app-subnet-1.id}"
  metadata {
    ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0G5R0I21xfA0PyCFOI+TCRqSGtuEbAO9c7zRsE652jQ/LDGLS6uCL+U3eB4+e8FnnRF3A1IB9jPO7pLvhbL9nlD2PbOwqmWMp4W3a8xyjjHEcTaQ9Hc085GDtUki6hyW4+jtJ3GdK5Wp7liH438tND6EAdVeUcrt07/o99eKeDjtTd6R5AeL08JPW7OuEYLcYHH2ZkMyu795XuWAIQXeDMfbnLj6gcTgyftVZViGPoELO39Cl7g/JxVXsnNTCVtTa5CRRmaF/mKVcGuj+5fiTafx8CNh/6hkBm2hryBdTcSwGkiZgXs1GkOfmEEkk+61kNJbpHSo0FiBz1h4B91zD jamescalise@Jamess-MacBook-Pro.local"
  }
}

data "baremetal_core_vnic_attachments" "vnics" {
  compartment_id = "${lookup(var.compartments,"demo")}"
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[0],"name")}"
  instance_id = "${baremetal_core_instance.standard-server.id}"
}

data "baremetal_core_vnic" "vnic" {
  vnic_id = "${lookup(data.baremetal_core_vnic_attachments.vnics.vnic_attachments[0],"vnic_id")}"
}

#resource "baremetal_load_balancer_backendset" "app-backend-set" {
#  load_balancer_id = "${baremetal_load_balancer.test-lb.id}"
#  name             = "appbackendset"
#  policy           = "ROUND_ROBIN"
#  health_checker {
#    port                = 80
#    protocol            = "HTTP"
#    response_body_regex = "te"
#  }
#}

resource "baremetal_load_balancer_backend" "app" {
  load_balancer_id = "${baremetal_load_balancer.test-lb.id}"
  backendset_name  = "tomcat"
  name             = "app1"
  ip_address       = "${data.baremetal_core_vnic.vnic.private_ip_address}"
  port             = 8080
  weight           = 1
}