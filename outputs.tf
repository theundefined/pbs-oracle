## Copyright (c) 2021, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "generated_ssh_private_key" {
  value     = tls_private_key.public_private_key_pair.private_key_pem
  sensitive = true
}

output "ssh" {
  value = "ssh ubuntu@${oci_core_instance.compute_instance.public_ip}"
}

output "pbs_url" {
  value = "https://${oci_core_instance.compute_instance.public_ip}:8007/"
}

output "root_password" {
  value     = random_password.rootpassword.result
  sensitive = true
}
