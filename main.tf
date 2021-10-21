// ssh-key
module "key" {
  source     = "git::github.com/andrewpopa/terraform-metal-project-ssh-key"
  project_id = var.project_id
}

// request elastic ip
module "ip" {
  source      = "git::git@github.com:andrewpopa/terraform-metal-reserved-ip-block.git"
  project_id  = var.project_id
  quantity    = var.quantity
  facility    = var.facility
  description = var.description
}

// configuring ElasticIP for the device
data "template_file" "this" {
  template = file("bootstrap/pkg.sh")
  vars = {
    ip      = module.ip.cidr_notation
    netmask = module.ip.netmask
  }
}

// create the device
module "device" {
  source              = "git::github.com/andrewpopa/terraform-metal-device.git"
  count               = 2
  hostname            = "ubuntu-userdata-${count.index}"
  plan                = "t1.small.x86"
  facilities          = ["ams1"]
  operating_system    = "ubuntu_18_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = [module.key.id]
  user_data           = data.template_file.this.rendered
}

resource "metal_bgp_session" "this" {
  count          = 2
  device_id      = module.device["${count.index}"].id
  address_family = "ipv4"
}