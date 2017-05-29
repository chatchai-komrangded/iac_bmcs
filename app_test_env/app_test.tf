provider "baremetal" {
  tenancy_ocid         = "${var.tenancy_ocid}"
  user_ocid            = "${var.user_ocid}"
  fingerprint          = "${var.fingerprint}"
  private_key_path     = "${var.private_key_path}"
  region               = "${var.region}"
}

data "baremetal_identity_availability_domains" "ads" {
  compartment_id = "${var.tenancy_ocid}"
}

resource "baremetal_core_virtual_network" "vcn" {
  cidr_block = "10.0.0.0/16"
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  display_name = "${var.identifier}-${var.customer}-Network"
  dns_label = "${var.customer}"
}

resource "baremetal_core_internet_gateway" "internet-gateway" {
    compartment_id =  "${lookup(var.compartments,var.compartment)}"
    display_name = "Public-IG"
    vcn_id = "${baremetal_core_virtual_network.vcn.id}"
}

resource "baremetal_core_route_table" "route-table" {
    compartment_id = "${lookup(var.compartments,var.compartment)}"
    vcn_id = "${baremetal_core_virtual_network.vcn.id}"
    display_name = "Public-RT"
    route_rules {
        cidr_block = "0.0.0.0/0"
        network_entity_id = "${baremetal_core_internet_gateway.internet-gateway.0.id}"
    }
}

resource "baremetal_core_dhcp_options" "bastion-dhcp" {
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  display_name = "bastion-dhcp"
  options {
    type = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
  options {
    type = "SearchDomain"
    search_domain_names = ["bastion.${var.identifier}.oraclevcn.com"]
  }
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
}

resource "baremetal_core_dhcp_options" "app-dhcp" {
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  display_name = "app-dhcp"
  options {
    type = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
  options {
    type = "SearchDomain"
    search_domain_names = ["app.${var.identifier}.oraclevcn.com"]
  }
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
}

resource "baremetal_core_dhcp_options" "db-dhcp" {
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  display_name = "db-dhcp"
  options {
    type = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
  options {
    type = "SearchDomain"
    search_domain_names = ["db.${var.identifier}.oraclevcn.com"]
  }
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
}


resource "baremetal_core_security_list" "lb-sl" {
  compartment_id ="${lookup(var.compartments,var.compartment)}"
  display_name = "LB-SL"
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
  cidr_block = "${cidrsubnet("10.0.0.0/24",4,0)}"
  display_name = "LB-1"
  dns_label = "lb1"
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.lb-sl.id}"]
  provisioner "local-exec"  {
    command = "sleep 10"
  }
}

resource "baremetal_core_subnet" "lb-subnet-2" {
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[1],"name")}"
  cidr_block = "${cidrsubnet("10.0.0.0/24",4,1)}"
  display_name = "LB-2"
  dns_label = "lb2"
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.lb-sl.id}"]
  provisioner "local-exec"  {
    command = "sleep 10"
  }
}

resource "baremetal_core_security_list" "bastion-sl" {
  compartment_id ="${lookup(var.compartments,var.compartment)}"
  display_name = "BASTION-SL"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  egress_security_rules =
  [{
    destination = "0.0.0.0/0"
    protocol = "6"
  }]
  ingress_security_rules =
  [{
    tcp_options {
      max = "22"
      min = "22"
    }
    protocol = "6"
    source= "0.0.0.0/0"
  }]
}

resource "baremetal_core_subnet" "bastion-subnet" {
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[var.ad - 1],"name")}"
  cidr_block = "${cidrsubnet("10.0.1.0/24",4,0)}"
  display_name = "BASTION"
  dns_label = "bastion"
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.bastion-sl.id}"]
  dhcp_options_id = "${baremetal_core_dhcp_options.bastion-dhcp.id}"
  provisioner "local-exec"  {
    command = "sleep 10"
  }
}

resource "baremetal_core_security_list" "app-sl" {
    compartment_id ="${lookup(var.compartments,var.compartment)}"
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
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[var.ad - 1],"name")}"
  cidr_block = "${cidrsubnet("10.0.2.0/24",4,0)}"
  display_name = "APP"
  dns_label = "app"
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.app-sl.id}"]
  dhcp_options_id = "${baremetal_core_dhcp_options.app-dhcp.id}"

  provisioner "local-exec"  {
    command = "sleep 10"
  }
}


resource "baremetal_core_security_list" "db-sl" {
  compartment_id ="${lookup(var.compartments,var.compartment)}"
  display_name = "DB-SL"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol = "6"
  }
  ingress_security_rules =
  [{
    tcp_options {
      max = "3306"
      min = "3306"
    }
    protocol = "6"
    source= "10.0.2.0/24"
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

resource "baremetal_core_subnet" "db-subnet-1" {
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[var.ad - 1],"name")}"
  cidr_block = "${cidrsubnet("10.0.3.0/24",4,0)}"
  display_name = "DB"
  dns_label = "db"
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.db-sl.id}"]
  dhcp_options_id = "${baremetal_core_dhcp_options.db-dhcp.id}"
  provisioner "local-exec"  {
    command = "sleep 10"
  }
}


module "bastion-1" {
  source = "../modules/base/server-config"
  compartment_name = "${lookup(var.compartments, var.compartment)}"
  image_name = "${var.region == "us-phoenix-1" ? "ocid1.image.oc1.phx.aaaaaaaawcvuel67op5mvot77kfrtruywsxy6byvx7haac5b6uih45migqrq" : "ocid1.image.oc1.iad.aaaaaaaaqosg7kfw6a4usld7fkq4vwgoqkdmirvzmvapi4t3iftgwjeh5qrq"}"
  ad_name = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[var.ad - 1],"name")}"
  server_display_name = "${var.identifier}-bastion"
  hostname = "${var.identifier}-bastion"
  shape_name = "${lookup(var.shapes, "VM1")}"
  subnet_name = "${baremetal_core_subnet.bastion-subnet.0.id}"
  public_key = "${lookup(var.ssh_key, "jim")}"
}

module "db-server" {
  source = "../modules/mysql-server"
  compartment_name = "${lookup(var.compartments, var.compartment)}"
  ad_name = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[var.ad - 1],"name")}"
  server_display_name = "${var.identifier}-mysql"
  hostname = "${var.identifier}-mysql"
  shape_name = "${lookup(var.shapes, var.shape)}"
  subnet_name = "${baremetal_core_subnet.db-subnet-1.id}"
  public_key = "${lookup(var.ssh_key, "jim")}"
  manage_with_omc = "${var.manage_with_omc}"
  bastion_host="${module.bastion-1.public_ip[0]}"
  bastion_private_key_path="${var.bastion_key}"
  devops_key = "${var.devops_key}"
  chef_key = "${var.chef_key}"
  customer = "${var.customer}"
  region = "${var.region}"
}

module "tomcat-server" {
  source = "../modules/tomcat-server"
  compartment_name = "${lookup(var.compartments, var.compartment)}"
  ad_name = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[var.ad - 1],"name")}"
  server_display_name = "${var.identifier}-tomcat"
  hostname = "${var.identifier}-tomcat"
  shape_name = "${lookup(var.shapes, var.shape)}"
  subnet_name = "${baremetal_core_subnet.app-subnet-1.id}"
  public_key = "${lookup(var.ssh_key, "jim")}"
  manage_with_omc = "${var.manage_with_omc}"
  bastion_host="${module.bastion-1.public_ip[0]}"
  bastion_private_key_path="${var.bastion_key}"
  devops_key = "${var.devops_key}"
  chef_key = "${var.chef_key}"
  region = "${var.region}"
}

#resource "baremetal_load_balancer" "app-lb" {
#  shape          = "100Mbps"
#  compartment_id = "${lookup(var.compartments,var.compartment)}"
#  subnet_ids     = ["${baremetal_core_subnet.lb-subnet-1.id}","${baremetal_core_subnet.lb-subnet-2.id}"]
#  display_name   = "${var.customer}LB"
#  provisioner "local-exec"  {
#    command = "sleep 60"
#  }
#}


#resource "baremetal_load_balancer_backendset" "tomcat-backendset" {
#  load_balancer_id = "${baremetal_load_balancer.app-lb.id}"
#  name             = "app_set"
#  policy           = "ROUND_ROBIN"
#}


#resource "baremetal_load_balancer_backend" "tomcat-server" {
#  load_balancer_id = "${baremetal_load_balancer.app-lb.id}"
#  backendset_name  = "${baremetal_load_balancer_backendset.tomcat-backendset.name}"
#  name             = "tomcat-server"
#  ip_address       = "${element(module.tomcat-server.private_ip,0)}"
#  port             = 8080
#  backup           = false
#  drain            = false
#  offline          = false
#  weight           = 1
#  provisioner "local-exec"  {
#    command = "sleep 60"
# }
#}

#resource "baremetal_load_balancer_listener" "app-listener" {
#  load_balancer_id         = "${baremetal_load_balancer.app-lb.id}"
#  name                     = "${var.customer}-app-listener"
#  default_backend_set_name = "${baremetal_load_balancer_backendset.tomcat-backendset.name}"
#  port                     = 80
#  protocol                 = "HTTP"
#  provisioner "local-exec"  {
#    command = "sleep 60"
#  }

#}