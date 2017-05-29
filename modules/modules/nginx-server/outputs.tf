output "public_ip" {
  value = ["${module.nginx-server.public_ip}"]
}

output "private_ip" {
  value = ["${module.nginx-server.private_ip}"]
}

output "ocid" {
  value = ["${module.nginx-server.ocid}"]
}
