#--- Openstack keystone authentication
variable "openstack_domain" {}

variable "openstack_project" {}
variable "region" {}
variable "auth_url" {}
variable "openstack_username" {}
variable "openstack_password" {}
variable "net_id" {}


#--- VPC COA
variable "vpc_coa_cidr" {}

#--- Nat-Gateway
variable "natgw_cidr" {}

variable "natgw_private_ip" {}

variable "dns_list" {
  type    = "list"
  default = ["8.8.8.8", "8.8.4.4"]
}

#========================================================================
# Vars needed for bootstrap
#========================================================================
#--- ssh instances key
variable "default_key_name" {}

#--- Instances
variable "public_image_id" {
  description = "#--- Ubuntu public image id"
  default     = "cab2f9bb-9dfd-483b-ba61-7d40b2ac2a04"
}

variable "az" {}
