

module "mysql-server" {
  source = "../base/server-config"
  compartment_name = "${var.compartment_name}"
  image_name = "${var.region == "us-phoenix-1" ? "ocid1.image.oc1.phx.aaaaaaaaqdyh2bhw35d4zftxqlmjtcqaz67hppkz5dg4azaz7ibj3panowgq" : "ocid1.image.oc1.iad.aaaaaaaa22rde66vbqx5cg7vllfzoyaux572dusbsgra4fy4yldu5a6iqbbq"}"
  ad_name = "${var.ad_name}"
  server_display_name = "${var.server_display_name}"
  hostname = "${var.hostname}"
  shape_name = "${var.shape_name}"
  subnet_name = "${var.subnet_name}"
  public_key = "${var.public_key}"
}

resource "null_resource" "server_instance_config"{
  count = "${1 - var.manage_with_omc}"
  provisioner "chef"  {
    on_failure = "continue"
    attributes_json = <<-EOF
          {
            "database":{
              "root_password":"Welcome1#",
              "admin_password":"Welcome1#",
              "customer":"${var.customer}"
            }
          }
          EOF
    run_list = ["bmc_servers::default","bmc_servers::database_config"]
    node_name = "${var.server_display_name}"
    server_url = "https://api.chef.io/organizations/bmc_devops"
    recreate_client = true
    user_name = "bmc_devops-validator"
    user_key = "${file(var.chef_key)}"
    version = "13.0.113"
    connection {
      host = "${module.mysql-server.private_ip}"
      type = "ssh"
      user = "opc"
      private_key = "${file(var.devops_key)}"
      bastion_host = "${var.bastion_host}"
      bastion_private_key = "${file(var.bastion_private_key_path)}"
      bastion_user = "opc"
      timeout = "3m"
    }
  }

}
