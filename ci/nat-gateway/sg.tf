data "openstack_networking_secgroup_v2" "secgroup" {
  name = "tf-default-sg"
}

data "openstack_networking_secgroup_v2" "secgroup" {
  name = "bootstrap-sg"
}

data "openstack_networking_secgroup_v2" "secgroup" {
 name = "coa-sg"
}
