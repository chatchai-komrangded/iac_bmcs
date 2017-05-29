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

resource "baremetal_core_dhcp_options" "bastion1-dhcp" {
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

resource "baremetal_core_dhcp_options" "app1-dhcp" {
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

resource "baremetal_core_subnet" "bastion-subnet" {
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[var.ad - 1],"name")}"
  cidr_block = "${cidrsubnet("10.0.1.0/24",4,0)}"
  display_name = "BASTION"
  dns_label = "bastion"
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.bastion-sl.id}"]
  dhcp_options_id = "${baremetal_core_dhcp_options.bastion1-dhcp.id}"
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
  cidr_block = "${cidrsubnet("10.0.3.0/24",4,0)}"
  display_name = "APP"
  dns_label = "app"
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.app-sl.id}"]
  dhcp_options_id = "${baremetal_core_dhcp_options.app1-dhcp.id}"
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
      max = "1521"
      min = "1521"
    }
    protocol = "6"
    source= "10.0.3.0/24"
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
  cidr_block = "${cidrsubnet("10.0.4.0/24",4,0)}"
  display_name = "DB"
  dns_label = "db"
  compartment_id = "${lookup(var.compartments,var.compartment)}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.db-sl.id}"]
  prohibit_public_ip_on_vnic = true
  provisioner "local-exec"  {
    command = "sleep 10"
  }
}

module "bastion-1" {
  source = "../modules/base/server-config"
  compartment_name = "${lookup(var.compartments, var.compartment)}"
  image_name = "${var.region == "us-phoenix-1" ? "ocid1.image.oc1.phx.aaaaaaaawcvuel67op5mvot77kfrtruywsxy6byvx7haac5b6uih45migqrq" : "ocid1.image.oc1.iad.aaaaaaaaqosg7kfw6a4usld7fkq4vwgoqkdmirvzmvapi4t3iftgwjeh5qrq"}"
  ad_name = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[var.ad - 1],"name")}"
  server_display_name = "${var.identifier}-bastion-1"
  hostname = "${var.identifier}-bastion1"
  shape_name = "${lookup(var.shapes, "VM1")}"
  subnet_name = "${baremetal_core_subnet.bastion-subnet.0.id}"
  public_key = "${lookup(var.ssh_key, "jim")}"
}


resource "baremetal_database_db_system" "tomcat-db" {
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ads.availability_domains[var.ad - 1],"name")}"
  compartment_id = "${lookup(var.compartments, var.compartment)}"
  cpu_core_count = 2
  database_edition = "ENTERPRISE_EDITION"
  db_home {
    database {
      "admin_password" = "WElcome11##"
      "db_name" = "tomcat"
    }
    db_version = "12.1.0.2"
    display_name = "Tomcat_DB"
  }
  disk_redundancy = "HIGH"
  shape = "${lookup(var.shapes, var.db_shape)}"
  subnet_id = "${baremetal_core_subnet.db-subnet-1.0.id}"
  ssh_public_keys = ["${lookup(var.ssh_key, "jim")}"]
  display_name = "TomcatDB"
  domain = "demo.com"
  hostname = "tomcatdb"
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
