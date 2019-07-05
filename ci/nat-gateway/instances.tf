#--- Nat Gateway Instance
resource "template_file" "tf-install-natgw" {
  template = "${file("install-natgw.sh")}"
  vars {
    vpc_paas_cidr    = "${var.vpc_paas_cidr}"
    natgw_private_ip = "${var.natgw_private_ip}"
  }
}

resource "openstack_blockstorage_volume_v2" "tf-natgw-sysvol" {
  availability_zone = "${var.availability_zone}"
  name              = "tf-natgw-sysvol"
  size              = 40
  image_id          = "${var.public_image_id}"
  volume_type       = "SATA"
}

resource "openstack_compute_instance_v2" "tf-natgw" {
  depends_on       = ["openstack_networking_port_v2.tf-natgw-port"]
  availability_zone = "${var.availability_zone}"
  name              = "natgw"
  flavor_name       = "c2.large"
  key_pair          = "${var.key_pair_name}"
  user_data         = "${template_file.tf-install-natgw.rendered}"

  block_device  {
    uuid                  = "${openstack_blockstorage_volume_v2.tf-natgw-sysvol.id}"
    source_type           = "volume"
    destination_type      = "volume"
    volume_size           = "${openstack_blockstorage_volume_v2.tf-natgw-sysvol.size}"
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    port           = "${openstack_networking_port_v2.tf-natgw-port.id}"
    access_network = true
  }
}