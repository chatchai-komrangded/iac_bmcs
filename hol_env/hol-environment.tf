############### Configure Baremetal Credential ###############
provider "baremetal" {
  tenancy_ocid = "${var.tenancy_ocid}"
  user_ocid = "${var.user_ocid}"
  fingerprint = "${var.fingerprint}"
  private_key_path = "${var.private_key_path}"
  private_key_password = "${var.private_key_password}"
}





############### Create Baremetal VCN ###############
resource "baremetal_core_virtual_network" "vcn" {
  cidr_block = "10.0.0.0/16"
  compartment_id = "${var.compartment_ocid}"
  display_name = "${var.identifier}-CoreNetwork"
}

############### Create Internet Gateway ###############
resource "baremetal_core_internet_gateway" "internet-gateway" {
    compartment_id =  "${var.compartment_ocid}"
    display_name = "Public-IG"
    vcn_id = "${baremetal_core_virtual_network.vcn.id}"
}

############### Create Route Table ###############
resource "baremetal_core_route_table" "route-table" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${baremetal_core_virtual_network.vcn.id}"
    display_name = "Public-RT"
    route_rules {
        cidr_block = "0.0.0.0/0"
        network_entity_id = "${baremetal_core_internet_gateway.internet-gateway.0.id}"
    }
}





######################################################### SECURITY LIST #########################################################
############### Create Security List for "Bastion (JumpBox)" Host ###############
resource "baremetal_core_security_list" "bastion-sl" {
    compartment_id ="${var.compartment_ocid}"
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

############### Create Security List for "Load Balance" ###############
resource "baremetal_core_security_list" "lb-sl" {
    compartment_id ="${var.compartment_ocid}"
    display_name = "LB-SL"
    vcn_id = "${baremetal_core_virtual_network.vcn.id}"
    egress_security_rules {
        destination = "0.0.0.0/0"
        protocol = "6"
    }
    ingress_security_rules =
    [{
      tcp_options {
          max = "80"
          min = "80"
      }
      protocol = "6"
      source= "0.0.0.0/0"
    }]
}

############### Create Security List for "WebServer" ###############
resource "baremetal_core_security_list" "app-sl" {
    compartment_id ="${var.compartment_ocid}"
    display_name = "APP-SL"
    vcn_id = "${baremetal_core_virtual_network.vcn.id}"
    egress_security_rules {
        destination = "0.0.0.0/0"
        protocol = "6"
    }
    ingress_security_rules =
    [{
      tcp_options {
          max = "3000"
          min = "3000"
      }
      protocol = "6"
      source= "0.0.0.0/0"
    },
   # {
   #   protocol = "6"
   #   source= "0.0.0.0/0"
   # },
    {
      tcp_options {
          max = "22"
          min = "22"
      }
      protocol = "6"
      source= "10.0.1.0/24"
    }]
}





######################################################### VCN SUBNET #########################################################
############### Create VCN SUBNET for "Bastion (JumpBox)" ###############
resource "baremetal_core_subnet" "bastion-subnet" {
  count = 3
  availability_domain = "${lookup(var.ad, "ad-${count.index % 3}")}"
  cidr_block = "${cidrsubnet("10.0.1.0/24",4,count.index)}"
  display_name = "BASTION-${count.index+1}"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.bastion-sl.id}"]
}

############### Create VCN SUBNET for "Load balance on ADx" ###############
resource "baremetal_core_subnet" "lb-subnet1" {
  availability_domain = "${lookup(var.ad, "ad-${0 % 3}")}"
  cidr_block = "${cidrsubnet("10.0.2.0/24",4,0)}"
  display_name = "LB-1"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.lb-sl.id}"]
}

############### Create VCN SUBNET for "Load balance on ADx" ###############
resource "baremetal_core_subnet" "lb-subnet2" {
  availability_domain = "${lookup(var.ad, "ad-${1 % 3}")}"
  cidr_block = "${cidrsubnet("10.0.2.0/24",4,1)}"
  display_name = "LB-2"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.lb-sl.id}"]
}

############### Create VCN SUBNET for "WebServer on ADx" ###############
resource "baremetal_core_subnet" "app-subnet-1" {
  availability_domain = "${lookup(var.ad, "ad-${0 % 3}")}"
  cidr_block = "${cidrsubnet("10.0.3.0/24",4,0)}"
  display_name = "APP-1"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.app-sl.id}"]
}

############### Create VCN SUBNET for "WebServer on ADx" ###############
resource "baremetal_core_subnet" "app-subnet-2" {
  availability_domain = "${lookup(var.ad, "ad-${1 % 3}")}"
  cidr_block = "${cidrsubnet("10.0.3.0/24",4,1)}"
  display_name = "APP-2"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.app-sl.id}"]
}

############### Create VCN SUBNET for "WebServer on ADx" ###############
resource "baremetal_core_subnet" "app-subnet-3" {
  availability_domain = "${lookup(var.ad, "ad-${2 % 3}")}"
  cidr_block = "${cidrsubnet("10.0.3.0/24",4,2)}"
  display_name = "APP-3"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${baremetal_core_virtual_network.vcn.id}"
  route_table_id = "${baremetal_core_route_table.route-table.0.id}"
  security_list_ids = ["${baremetal_core_security_list.app-sl.id}"]
}





############### Create Bootstrap Script to confiugre "WebServer" ###############
variable "InstanceBootStrap" {
  default = "/home/jenkins/tfiac/bmcs_demo/server-config/HOL-CloudInit.yaml"
}





######################################################### Resource Provisioning (WEB,APP,DB,ETC) #########################################################
############### Provision "WebServer1" on AD1 ###############
resource "baremetal_core_instance" "App1" {
  availability_domain = "YZAF:PHX-AD-1"
  compartment_id = "${var.compartment_ocid}"
  display_name = "App1"
  image = "ocid1.image.oc1.phx.aaaaaaaazt3sfrz2lfbha6okihvh4bwaufikhilhsek43hpvzxitl47nv2bq"
  shape = "VM.Standard1.2"
  subnet_id = "${baremetal_core_subnet.app-subnet-1.id}"
  metadata {
    ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEArn21PGy1SZ6AYFlztFUL1gv63EXMbSb4qo1SzPAwZgcQXjciU8YsettV81YIFzvIedEn4mhD8ebGKK1k8oYB7HYNsSywbXmqisI+75xY37EZT6ah+cxENmVxmzpOjOYH31wj792tf/WpUUpnN8MdIlTW8uAWNIa6Mz9YhAZ0sJILDOlSNr/rorrGYyYLBtJqbVAZlwEfUSgQTkMwBWK4L7aXOLMDFFAi2oEqsjmT3rWX55YzrwXIMvNXjslen6gXqrdoCeakKMbQ788fQqb1P9hgsmHhkERJfwhgFy+R1RUfPMHdZG7P2vNLUZDd54ROCmj2F852HkertpDMFNMWrQ== oracle@oraclelinux6.localdomain"
	user_data = "${base64encode(file(var.InstanceBootStrap))}"
  }
}

############### Provision "WebServer2" on AD2 ###############
resource "baremetal_core_instance" "App2" {
  availability_domain = "YZAF:PHX-AD-2"
  compartment_id = "${var.compartment_ocid}"
  display_name = "App2"
  image = "ocid1.image.oc1.phx.aaaaaaaazt3sfrz2lfbha6okihvh4bwaufikhilhsek43hpvzxitl47nv2bq"
  shape = "VM.Standard1.2"
  subnet_id = "${baremetal_core_subnet.app-subnet-2.id}"
  metadata {
    ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEArn21PGy1SZ6AYFlztFUL1gv63EXMbSb4qo1SzPAwZgcQXjciU8YsettV81YIFzvIedEn4mhD8ebGKK1k8oYB7HYNsSywbXmqisI+75xY37EZT6ah+cxENmVxmzpOjOYH31wj792tf/WpUUpnN8MdIlTW8uAWNIa6Mz9YhAZ0sJILDOlSNr/rorrGYyYLBtJqbVAZlwEfUSgQTkMwBWK4L7aXOLMDFFAi2oEqsjmT3rWX55YzrwXIMvNXjslen6gXqrdoCeakKMbQ788fQqb1P9hgsmHhkERJfwhgFy+R1RUfPMHdZG7P2vNLUZDd54ROCmj2F852HkertpDMFNMWrQ== oracle@oraclelinux6.localdomain"
	user_data = "${base64encode(file(var.InstanceBootStrap))}"
  }
}

############### Provision "WebServer3" on AD3 ###############
resource "baremetal_core_instance" "App3" {
  availability_domain = "YZAF:PHX-AD-3"
  compartment_id = "${var.compartment_ocid}"
  display_name = "App3"
  image = "ocid1.image.oc1.phx.aaaaaaaazt3sfrz2lfbha6okihvh4bwaufikhilhsek43hpvzxitl47nv2bq"
  shape = "VM.Standard1.2"
  subnet_id = "${baremetal_core_subnet.app-subnet-3.id}"
  metadata {
    ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEArn21PGy1SZ6AYFlztFUL1gv63EXMbSb4qo1SzPAwZgcQXjciU8YsettV81YIFzvIedEn4mhD8ebGKK1k8oYB7HYNsSywbXmqisI+75xY37EZT6ah+cxENmVxmzpOjOYH31wj792tf/WpUUpnN8MdIlTW8uAWNIa6Mz9YhAZ0sJILDOlSNr/rorrGYyYLBtJqbVAZlwEfUSgQTkMwBWK4L7aXOLMDFFAi2oEqsjmT3rWX55YzrwXIMvNXjslen6gXqrdoCeakKMbQ788fQqb1P9hgsmHhkERJfwhgFy+R1RUfPMHdZG7P2vNLUZDd54ROCmj2F852HkertpDMFNMWrQ== oracle@oraclelinux6.localdomain"
	user_data = "${base64encode(file(var.InstanceBootStrap))}"
  }
}





######################################################### Load Balance Provisioning #########################################################
############### Provision Load Balance, Specific Bandwidth that can be served 100 MBps  ###############
#resource "baremetal_load_balancer" "App-lb" {
#  shape          = "100Mbps"
#  compartment_id = "${var.compartment_ocid}"
#  subnet_ids     = ["${baremetal_core_subnet.lb-subnet1.id}","${baremetal_core_subnet.lb-subnet2.id}"]
#  display_name   = "App-lb"
#  provisioner "local-exec"  {
#    command = "sleep 60"
#  }
#}

############### Provision Elastic Load Balance BackendSet  ###############
#resource "baremetal_load_balancer_backendset" "meanstack-backendset" {
#  load_balancer_id = "${baremetal_load_balancer.App-lb.id}"
#  name             = "App-backendset"
#  policy           = "ROUND_ROBIN"
#}


#resource "baremetal_load_balancer_listener" "MEANApp-listener" {
#  load_balancer_id         = "${baremetal_load_balancer.App-lb.id}"
#  name                     = "App-listener"
#  default_backend_set_name = "${baremetal_load_balancer_backendset.meanstack-backendset.name}"
#  port                     = 9090
#  protocol                 = "HTTP"
#  provisioner "local-exec"  {
 #   command = "sleep 60"
 # }
#}








#module "hol-server-2" {
#  source = "../modules/server-config"
  #source = "git::ssh://git@bitbucket.aka.lgl.grungy.us:7999/pm/tf-bmcs-modules.git//backend-hol?ref=v0.0.3"
#  compartment_id = "${var.compartment_ocid}"
 # image_name = "ocid1.image.oc1.phx.aaaaaaaaclseho77fcdfgejstt2bflkugcx5waa6bhconbokvhdp3qw7txlq"
  #ad_name = "${lookup(var.ad, "ad-1")}"
 # server_display_name = "${var.server2_name}"
 # hostname = "${var.server2_name}.omcdemo"
 # shape_name = "${lookup(var.shape, "VM2")}"
 # subnet_name = "${baremetal_core_subnet.app-subnet-2.id}"
 # public_key = "${lookup(var.ssh_key, "jenkins")}"
 # cloud_init_file = "../server-config/HOL-CloudInit.yaml"
 # omc = {
 #   configure = "no"
 #   omc_key = "RG_5BZtGjaTtLbAVRGpitu6UVA"
 #   private_key_path = "/var/lib/jenkins/.ssh/id_jim_rsa"
 #   entity_file       = "${data.template_file.omc_entity-2.rendered}"
 # }
 # bastion = {
 #   host="${module.bastion-1.public_ip[0]}"
 #   private_key_path="${var.private_key_path}"
  #}
#}


