terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.28.0"
    }
  }
}

provider "digitalocean" {}

data "digitalocean_ssh_key" "ssh_key" {
  name = "benchmark"
}

resource "digitalocean_droplet" "load-test-env" {
  image      = "ubuntu-22-04-x64"
  name       = "load-test-env"
  region     = "fra1"
  size       = "g-2vcpu-8gb"
  monitoring = true
  ssh_keys   = [data.digitalocean_ssh_key.ssh_key.id]

  # Forces terraform to wait until the droplet has boot up.
  provisioner "remote-exec" {
    inline = [
      "echo Droplet Created Successfully!"
    ]

    connection {
      host        = self.ipv4_address
      user        = "root"
      type        = "ssh"
      private_key = file("../tf-digitalocean")
    }
  }
}

resource "local_file" "load-test-env-ipv4" {
  filename = "./load-test-env-ipv4"
  content = digitalocean_droplet.load-test-env.ipv4_address
}
