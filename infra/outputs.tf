output "cluster_endpoint" {
  value = google_container_cluster.autopilot.endpoint
}

output "artifact_repo" {
  value = google_artifact_registry_repository.repo.repository_url
}
