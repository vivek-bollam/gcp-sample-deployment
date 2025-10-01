terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "my-terraform-state"  # Create this bucket first or use local
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "sample-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "sample-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  private_ip_google_access = true
}

# Artifact Registry
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "my-repo"
  description   = "Sample Docker repo"
  format        = "DOCKER"
}

# GKE Autopilot Cluster
resource "google_container_cluster" "autopilot" {
  name               = "sample-autopilot"
  location           = var.region
  enable_autopilot   = true
  network            = google_compute_network.vpc.name
  subnetwork         = google_compute_subnetwork.subnet.name
  remove_default_node_pool = true
  initial_node_count = 1

  # VPC-native
  ip_allocation_policy {}

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Public endpoint (default)
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Enable logging/monitoring (basic observability)
  monitoring_config {
    enable_managed_prometheus = false
  }
  logging_config {
    managed_fields {
      enabled = true
    }
  }
}
