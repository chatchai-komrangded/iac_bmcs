

module "tomcat-server" {
  source = "../base/server-config"
  compartment_name = "${var.compartment_name}"
  image_name = "ocid1.image.oc1.phx.aaaaaaaaaqzcfylib7cjghxsdzal7rgxudocw2fnxmaypsgj7adw2x7eyunq"
  ad_name = "${var.ad_name}"
  server_display_name = "${var.server_display_name}"
  hostname = "${var.hostname}"
  shape_name = "${var.shape_name}"
  subnet_name = "${var.subnet_name}"
  public_key = "${var.public_key}"
}

resource "null_resource" "manager_server_instance_config"{
  count = "${var.manage_with_omc}"
  provisioner "chef"  {
          attributes_json = <<-EOF
          {
            "set_fqdn":"${var.hostname}.omc",
            "omc":{
                "regkey":"RvnWiqoF63rVq2ZW9G09Gu4W0N"
            }
          }
          EOF
          run_list = ["hostnames::default","bmc_servers::monitored_server","bmc_servers::monitored_helloworld_tomcat"]
          node_name = "${var.server_display_name}"
          server_url = "https://api.chef.io/organizations/bmc_devops"
          recreate_client = true
          user_name = "bmc_devops-validator"
          user_key = "${file(var.chef_key)}"
          version = "13.0.113"
          connection {
            host = "${module.tomcat-server.private_ip}"
            type = "ssh"
            user = "opc"
            private_key = "${file(var.devops_key)}"
            bastion_host = "${var.bastion_host}"
            bastion_private_key = "${file(var.bastion_private_key_path)}"
            bastion_user = "opc"
          }
  }
}

resource "null_resource" "server_instance_config"{
  count = "${1 - var.manage_with_omc}"
  provisioner "chef"  {
    attributes_json = <<-EOF
          {
            "set_fqdn":"${var.hostname}.omc",
           "env-omc":{
                "regkey":"RvnWiqoF63rVq2ZW9G09Gu4W0N"
            }
          }
          EOF
    run_list = ["bmc_servers::helloworld_tomcat"]
    node_name = "${var.server_display_name}"
    server_url = "https://api.chef.io/organizations/bmc_devops"
    recreate_client = true
    user_name = "bmc_devops-validator"
    user_key = "${file(var.chef_key)}"
    version = "13.0.113"
    connection {
      host = "${module.tomcat-server.private_ip}"
      type = "ssh"
      user = "opc"
      private_key = "${file(var.devops_key)}"
      bastion_host = "${var.bastion_host}"
      bastion_private_key = "${file(var.bastion_private_key_path)}"
      bastion_user = "opc"
    }
  }

}
