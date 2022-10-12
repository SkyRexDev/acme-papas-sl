output "balancer_ip_addr" {
  description = "Public IP address of the balancer"
  value       = google_compute_instance.balancer.network_interface.0.access_config.0.nat_ip
}

output "web_server_ip_addr" {
  description = "Public IP address of the web-server"
  value       = google_compute_instance.backend-web-server.network_interface.0.access_config.0.nat_ip
}