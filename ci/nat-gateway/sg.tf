data "openstack_networking_secgroup_v2" "tf-default-sg" {
  name = "tf-default-sg"
}

data "openstack_networking_secgroup_v2" "bootstrap-sg" {
  name = "bootstrap-sg"
}

data "openstack_networking_secgroup_v2" "coa-sg" {
 name = "coa-sg"
}
