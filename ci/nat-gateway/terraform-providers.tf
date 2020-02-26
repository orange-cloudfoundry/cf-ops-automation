provider "openstack" {
  insecure    = "true"
  domain_name = "${var.openstack_domain}"
  tenant_name = "${var.openstack_project}"
  region      = "${var.region}"
  auth_url    = "${var.auth_url}"
  user_name   = "${var.openstack_username}"
  password    = "${var.openstack_password}"
}
