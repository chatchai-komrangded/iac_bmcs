output "public_ip" {
  value = ["${data.baremetal_core_vnic.vnic.public_ip_address}"]
}

output "private_ip" {
  value = ["${data.baremetal_core_vnic.vnic.private_ip_address}"]
}

output "ocid" {
  value = ["${baremetal_core_instance.bastion-server.id}"]
}
