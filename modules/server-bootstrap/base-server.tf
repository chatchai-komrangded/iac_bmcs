resource "baremetal_core_instance" "base" {
  availability_domain = "${var.ad_name}"
  compartment_id = "${var.compartment_name}"
  display_name = "${var.server_display_name}"
  image = "${var.image_name}"
  shape = "${var.shape_name}"
  subnet_id = "${var.subnet_name}"
  metadata {
    ssh_authorized_keys = "${var.public_key}"
    user_data = "${base64encode(file("${path.module}/Oracle-CloudInit.yaml"))}"
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

resource "null_resource" "wait_for_cloudinit" {
  depends_on = ["baremetal_core_instance.base"]
  count = 1
  provisioner "remote-exec" {
        inline = [
         "while [ ! -f /tmp/signal ]; do sleep 2; done",
        ]
        connection {
          host = "${data.baremetal_core_vnic.vnic.public_ip_address}"
          type = "ssh"
          user = "opc"
          private_key = "${file(var.omc["private_key_path"])}"
        }
    }
}

resource "null_resource" "omc_instance_bootstrap"{
  depends_on = ["null_resource.wait_for_cloudinit"]
  count = "${var.omc["bootstrap"] == "yes" ? 1 : 0}"

  provisioner "remote-exec" {
        inline = [
         "sudo mkdir -p /u01",
         "sudo mkdir -p /u01/omc" ,
         "sudo mkdir -p /u01/omc/stage_one" ,
         "sudo mkdir -p /u01/omc/stage_two" ,
         "sudo chown -R oracle:oinstall /u01",
         "sudo rngd -r /dev/urandom -o /dev/random"
        ]
        connection {
          host = "${data.baremetal_core_vnic.vnic.public_ip_address}"
          type = "ssh"
          user = "oracle"
          private_key = "${file(var.omc["private_key_path"])}"
          timeout = "7m"
        }
    }

  # Copies the agentInstall.zip file to the /u01/omc directory
  provisioner "file" {
      source = "${var.omc["omc_agent_path"]}"
      destination = "/u01/omc/stage_one/agentInstall.zip"
      connection {
        host = "${data.baremetal_core_vnic.vnic.public_ip_address}"
        type = "ssh"
        user = "oracle"
        private_key = "${file(var.omc["private_key_path"])}"
        timeout = "7m"
      }
  }

  provisioner "remote-exec" {
        inline = [
        "unzip /u01/omc/stage_one/agentInstall.zip -d /u01/omc/stage_one",
        "chmod +x /u01/omc/stage_one/AgentInstall.sh",
        "/u01/omc/stage_one/AgentInstall.sh AGENT_TYPE=cloud_agent STAGE_LOCATION=/u01/omc/stage_two -download_only AGENT_REGISTRATION_KEY=${var.omc["omc_key"]}",
        "mkdir -p /u01/omc/app",
        ]
        connection {
          host = "${data.baremetal_core_vnic.vnic.public_ip_address}"
          type = "ssh"
          user = "oracle"
          private_key = "${file(var.omc["private_key_path"])}"
          timeout = "7m"
        }
    }
  }

resource "baremetal_core_image" "bootstrap_image" {
    depends_on = ["null_resource.wait_for_cloudinit","null_resource.omc_instance_bootstrap"]
    compartment_id = "${var.image["compartment"]}"
    display_name = "${var.image["name"]}"
    instance_id = "${baremetal_core_instance.base.id}"
}
