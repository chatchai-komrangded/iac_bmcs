resource "baremetal_core_instance" "base" {
  availability_domain = "${var.ad_name}"
  compartment_id = "${var.compartment_name}"
  display_name = "${var.server_display_name}"
  image = "${var.image_name}"
  shape = "${var.shape_name}"
  subnet_id = "${var.subnet_name}"
  metadata {
    ssh_authorized_keys = "${var.public_key}"
  }
}

data "baremetal_core_vnic_attachments" "vnics" {
      compartment_id = "${var.compartment_name}"
      availability_domain = "${var.ad_name}"
      instance_id = "${baremetal_core_instance.base.id}"
}
data "baremetal_core_vnic" "vnic" {
  vnic_id = "${lookup(data.baremetal_core_vnic_attachments.vnics.vnic_attachments[0],"vnic_id")}"
}

resource "null_resource" "bootstrap-omc" {
  depends_on = ["baremetal_core_instance.base"]

  provisioner "chef"  {
  run_list = ["bmc_servers::bootstrap","bmc_servers::bootstrap-omc"]
  node_name = "${var.server_display_name}"
  server_url = "https://api.chef.io/organizations/bmc_devops"
  recreate_client = true
  user_name = "bmc_devops-validator"
  user_key = "${file("/Users/jcalise/Projects/DevOps/chef-repo/.chef/bmc_devops-validator.pem")}"
  version = "13.0.113"
  connection {
    host = "${data.baremetal_core_vnic.vnic.private_ip_address}"
    type = "ssh"
    user = "opc"
    private_key = "${file(var.devops_key)}"
    bastion_host = "${var.bastion_host}"
    bastion_private_key = "${file(var.bastion_private_key_path)}"
    bastion_user = "opc"
  }
  }
}

resource "baremetal_core_image" "bootstrap-image" {
    depends_on = ["null_resource.bootstrap-omc"]
    compartment_id = "${var.custom_image_compartment}"
    display_name = "${var.custom_image_name}"
    instance_id = "${baremetal_core_instance.base.id}"
}
