## Copyright (c) 2021, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# This Terraform script provisions a compute instance

data "template_file" "cloud-config" {
  template = <<YAML
#cloud-config
runcmd:
 - apt-get update
 - apt -y full-upgrade
 - apt-get install -yq lxc lxc-templates lxc-utils swapspace
 - echo LXC_DHCP_CONFILE=/etc/lxc/dnsmasq.conf |tee -a /etc/default/lxc-net
 - echo dhcp-hostsfile=/etc/lxc/dnsmasq-hosts.conf |tee /etc/lxc/dnsmasq.conf
 - echo pbsdebian,10.0.2.2 |tee /etc/lxc/dnsmasq-hosts.conf
 - systemctl restart lxc-net
 - lxc-create -n pbsdebian -t download -- --dist debian --release bullseye --arch amd64
 - iptables -t nat -A POSTROUTING -s 10.0.2.0/24 -j MASQUERADE
 - iptables -t nat -A PREROUTING -p tcp --dport 8007 -j DNAT --to-destination 10.0.2.2
 - iptables -I FORWARD -s 10.0.2.0/24 -j ACCEPT
 - iptables -I FORWARD -d 10.0.2.0/24 -j ACCEPT
 - iptables -I INPUT -i lxcbr0 -p udp --dport 53 -j ACCEPT
 - iptables -I INPUT -i lxcbr0 -p udp --dport 67 -j ACCEPT
 - iptables-save |tee /etc/iptables/rules.v4
 - lxc-start -n pbsdebian
 - sleep 30
 - echo deb http://download.proxmox.com/debian/pbs bullseye pbs-no-subscription | lxc-attach -n pbsdebian -- tee /etc/apt/sources.list.d/pbs-backups.list
 - lxc-attach -n pbsdebian -- apt-get install -yq wget
 - lxc-attach -n pbsdebian -- wget https://enterprise.proxmox.com/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg
 - lxc-attach -n pbsdebian -- apt-get update
 - lxc-attach -n pbsdebian -- apt-get -y full-upgrade
 - echo "postfix postfix/mailname string pbs" | lxc-attach -n pbsdebian -- debconf-set-selections
 - echo "postfix postfix/main_mailer_type string 'Internet Site'" | lxc-attach -n pbsdebian -- debconf-set-selections
 - lxc-attach -n pbsdebian -- apt-get install -yqq proxmox-backup-server
 - echo root:"${random_password.rootpassword.result}" | lxc-attach -n pbsdebian -- chpasswd
 - lxc-attach -n pbsdebian -- /usr/sbin/proxmox-backup-manager datastore create backup /backup --gc-schedule daily daily
YAML
}

resource "oci_core_instance" "compute_instance" {
  availability_domain = var.availablity_domain_name == "" ? data.oci_identity_availability_domains.ADs.availability_domains[0]["name"] : var.availablity_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "pbs"
  shape               = var.instance_shape
  fault_domain        = "FAULT-DOMAIN-1"

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key == "" ? tls_private_key.public_private_key_pair.public_key_openssh : var.ssh_public_key
    user_data           = "${base64encode(data.template_file.cloud-config.rendered)}"
  }

  create_vnic_details {
    subnet_id                 = oci_core_subnet.subnet.id
    display_name              = "primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
  }

  source_details {
    source_type             = "image"
    source_id               = lookup(data.oci_core_images.InstanceImageOCID.images[0], "id")
    boot_volume_size_in_gbs = "80"
  }

  timeouts {
    create = "60m"
  }

}
