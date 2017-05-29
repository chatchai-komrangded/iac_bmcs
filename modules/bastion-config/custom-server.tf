resource "baremetal_core_instance" "bastion-server" {
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
      instance_id = "${baremetal_core_instance.bastion-server.id}"
}

data "baremetal_core_vnic" "vnic" {
  vnic_id = "${lookup(data.baremetal_core_vnic_attachments.vnics.vnic_attachments[0],"vnic_id")}"
}
