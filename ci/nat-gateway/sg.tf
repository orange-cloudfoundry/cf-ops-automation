resource "openstack_networking_secgroup_v2" "tf-default-sg" {
  name        = "tf-default-sg"
  description = "Default security group for bosh instances"
  region      = "${var.region}"
}

resource "openstack_networking_secgroup_v2" "bootstrap-sg" {
  name        = "bootstrap-sg"
  description = "Bootstrap security group for bosh instances"
  region      = "${var.region}"
}

