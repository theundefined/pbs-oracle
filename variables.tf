## Copyright (c) 2021, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "region" {}
variable "ssh_public_key" {
  default = ""
}
variable "compartment_ocid" {
}

variable "availablity_domain_name" {
  default = ""
}
variable "VCN-CIDR" {
  default = "10.0.0.0/16"
}

variable "Subnet-CIDR" {
  default = "10.0.1.0/24"
}

variable "instance_shape" {
  description = "Instance Shape"
  default     = "VM.Standard.E2.1.Micro"
}

variable "instance_ocpus" {
  default = 1
}

variable "instance_shape_config_memory_in_gbs" {
  default = 1
}

variable "instance_os" {
  description = "Operating system for compute instances"
  default     = "Canonical Ubuntu"
}

variable "linux_os_version" {
  description = "Operating system version for all Linux instances"
  default     = "22.04"
}
