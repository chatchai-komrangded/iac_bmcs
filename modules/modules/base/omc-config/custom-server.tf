resource "baremetal_core_instance" "custom-server" {
  availability_domain = "${var.ad_name}"
  compartment_id = "${var.compartment_name}"
  display_name = "${var.server_display_name}"
  image = "ocid1.image.oc1.phx.aaaaaaaawcvuel67op5mvot77kfrtruywsxy6byvx7haac5b6uih45migqrq"
  hostname_label = "${var.hostname}"
  shape = "${var.shape_name}"
  subnet_id = "${var.subnet_name}"
  metadata {
    ssh_authorized_keys = "${var.public_key}"
    user_data = "${base64encode(file("${var.cloud_init_file}"))}"
  }
}

data "baremetal_core_vnic_attachments" "vnics" {
      compartment_id = "${var.compartment_name}"
      availability_domain = "${var.ad_name}"
      instance_id = "${baremetal_core_instance.custom-server.id}"
}

data "baremetal_core_vnic" "vnic" {
  vnic_id = "${lookup(data.baremetal_core_vnic_attachments.vnics.vnic_attachments[0],"vnic_id")}"
}


data "template_file" "omc_entity" {
    count = "${var.manage_with_omc}"
    template = "${file("${path.module}/omc_linux_entity.tpl")}"
   vars {
      hostname = "${var.hostname}.omcdemo"
    }
}

resource "null_resource" "omc_instance_config"{
  count = "${var.manage_with_omc}"
  provisioner "file" {
      content = "${data.template_file.omc_entity.rendered}"
      destination = "/u01/omc/stage_two/omc_entity.json"
      connection {
        host = "${data.baremetal_core_vnic.vnic.private_ip_address}"
        type = "ssh"
        user = "oracle"
        private_key = "${file(var.devops_key)}"
        bastion_host = "${var.bastion["host"]}"
        bastion_private_key = "${file(var.bastion["private_key_path"])}"
        bastion_user = "opc"
      }
  }

   provisioner "remote-exec" {
        inline = [
        "while [ ! -f /tmp/signal ]; do sleep 2; done",
        "export local_ip=$(python -c 'import socket; print(socket.gethostbyname(socket.gethostname()))')",
        "export fqdn=$(python -c 'import socket; print(socket.getfqdn())')",
        "export hostname=$(hostname)",
        "sudo sh -c \"echo $local_ip $hostname.omcdemo $hostname >> /etc/hosts\"",
        "sudo perl -pi.omcbak -e 's/files dns myhostname/files dns/' /etc/nsswitch.conf",
        "/u01/omc/stage_two/AgentInstall.sh AGENT_TYPE=cloud_agent AGENT_BASE_DIR='/u01/omc/app/cloud_agent' -staged  AGENT_PROPERTIES=$PWD/agent.properties AGENT_REGISTRATION_KEY=${var.omc["omc_key"]}",
        "export core=$(/u01/omc/app/cloud_agent/agent_inst/bin/omcli status agent | grep '^Binaries Location' | awk -F: '{print $2}')",
        "sudo $core/root.sh",
        "/u01/omc/app/cloud_agent/agent_inst/bin/omcli update_entity agent /u01/omc/stage_two/omc_entity.json"
        ]
        connection {
          host = "${data.baremetal_core_vnic.vnic.private_ip_address}"
          type = "ssh"
          user = "oracle"
          private_key = "${file(var.devops_key)}"
          bastion_host = "${var.bastion["host"]}"
          bastion_private_key = "${file(var.bastion["private_key_path"])}"
          bastion_user = "opc"
        }
    }
  }
