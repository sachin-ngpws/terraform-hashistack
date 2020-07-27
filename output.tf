output "server_ip" {
  value = google_compute_instance.stack_server.network_interface[0].access_config[0].nat_ip
}
output "server_int_ip" {
  value = google_compute_instance.stack_server.network_interface[0].network_ip
}
output "client_ip" {
  value = google_compute_instance.stack_client.network_interface[0].access_config[0].nat_ip
}