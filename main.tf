terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  credentials = file("./credentials.json")
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private" {
  name          = "private"
  ip_cidr_range = "192.168.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "public" {
  name          = "public"
  ip_cidr_range = "192.168.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow-balancer-conections" {
  name          = "allow-balancer-connections"
  network       = google_compute_network.vpc_network.id
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["public"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

}

resource "google_compute_firewall" "allow-balancer-web-connections" {
  name        = "allow-balancer-web-connections"
  network     = google_compute_network.vpc_network.id
  source_tags = ["public"]
  target_tags = ["private"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

}

resource "google_compute_firewall" "allow-web-server-ssh" {
  name          = "allow-web-server-ssh"
  network       = google_compute_network.vpc_network.id
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["private"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

}

resource "google_compute_instance" "backend-web-server" {
  name         = "web-server"
  machine_type = "e2-small"
  tags         = ["private"]
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
    network_ip = "192.168.1.10"
    access_config {
    }

  }
  metadata_startup_script = file("./startup_web_server.sh")
}

resource "google_compute_instance" "balancer" {
  name         = "balancer"
  machine_type = "e2-small"
  tags         = ["public"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }


  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    network_ip = "192.168.0.10"
    access_config {
    }
  }
  metadata_startup_script = file("./startup_balancer.sh")
}

resource "google_compute_project_metadata" "my_ssh_key" {
  metadata = {
    ssh-keys = <<EOF
      guiruiga:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIwKoz3krR+GzL32dG2JDYkx/kUygfzbJC+3qAKSEWfcSXEomwOicuAjTrVNSUdQUHEYeFMNlAG/4NJJpcY5XOTRljQaMeqr0cFYTR9ME9MNJ51s04sUZnLITCrTor2yNec0l/TL9iMPZmoXjwCIG5F7/nLYEvmBGZraHuV/POzfHCNhZfrvhxcE1O4b3NCprTSxNUk20RdggdVCmYTCuQWVf6gWY+nELBNIXm0cqDezbOFbk+3eZmxK35Ku7wIX399ANAubS7CuXjKP7mkGxJuKPUOhU+LwbzPZ/g6+HAykvtafAzk5U0FuxS8G3bYUKMSi+TAdEwOxEOARJoDRCz guiruiga
    EOF
  }
}


