#--- Nat Gateway Network
resource "openstack_networking_network_v2" "tf_net_natgw" {
  name           = "tf_net_natgw"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "tf_subnet_natgw" {
  name            = "tf_subnet_natgw"
  network_id      = "${openstack_networking_network_v2.tf_net_natgw.id}"
  cidr            = "${var.natgw_cidr}"
  dns_nameservers = "${var.dns_list}"
  ip_version      = 4
}

resource "openstack_networking_router_interface_v2" "tf_router_interface_natgw" {
  region    = "${var.region}"
  router_id = "${var.net_id}"
  subnet_id = "${openstack_networking_subnet_v2.tf_subnet_natgw.id}"
}

resource "openstack_networking_router_route_v2" "tf_router_route_natgw" {
  depends_on       = ["openstack_networking_router_interface_v2.tf_router_interface_natgw"]
  router_id        = "${var.net_id}"
  destination_cidr = "0.0.0.0/0"
  next_hop         = "${var.natgw_private_ip}"
}


resource "openstack_networking_port_v2" "tf-natgw-port" {
  network_id         = "${openstack_networking_network_v2.tf_net_natgw.id}"
  security_group_ids = ["${data.openstack_networking_secgroup_v2.tf-default-sg.id}"]
  admin_state_up     = "true"
  fixed_ip           = {
    subnet_id        = "${openstack_networking_subnet_v2.tf_subnet_natgw.id}"
    ip_address       = "${var.natgw_private_ip}"
  }
  allowed_address_pairs = [{"ip_address" = "1.1.1.1/0"}]
  depends_on = [data.openstack_networking_secgroup_v2.tf-default-sg]
}

