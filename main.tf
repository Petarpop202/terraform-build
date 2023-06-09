provider "google" {
  credentials = file("credentials.json")
  project     = var.project
  region      = "us-central1"
}

provider "google-beta" {
  credentials = file("credentials.json")
  project     = var.project
  region      = "us-central1"
}

# Generating VPC and Subnets

resource "google_compute_network" "vpc-test" {
  name                    = "vpc-test"
  auto_create_subnetworks = true
}

# Firewall for allow-ssh and ports
resource "google_compute_firewall" "allow_ssh_test" {
  depends_on    = [google_compute_network.vpc-test]
  name          = "allow-ssh-test"
  network       = google_compute_network.vpc-test.id
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "test_firewall_rule" {
  depends_on    = [google_compute_network.vpc-test]
  name          = "test-firewall-rule"
  network       = google_compute_network.vpc-test.id
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["3000-3001"]
  }
}

# Create instance template

resource "google_compute_instance_template" "test_template" {
  depends_on   = [google_compute_network.vpc-test]
  name         = "test-template"
  machine_type = "n1-standard-1"

  disk {
    source_image = "projects/cloud-internship-petar/global/images/image-project1"
  }

  network_interface {
    network = google_compute_network.vpc-test.id

    access_config {}
  }

  tags = ["http-server"]

  metadata_startup_script = <<SCRIPT
cd /home/petarpop2001/project/cloud_student_internship/
cat > frontend/.env.development << EOF
REACT_APP_API_URL=http://$(curl ifconfig.me. ):3001/api
EOF
sudo docker-compose build
sudo docker-compose up -d
SCRIPT
}

resource "google_compute_firewall" "http_firewall_rule" {
  depends_on  = [google_compute_network.vpc-test]
  name        = "allow-http"
  network     = google_compute_network.vpc-test.id
  source_tags = ["http-server"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

module "mig" {
  depends_on    = [google_compute_instance_template.test_template]
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "~> 7.9"
  instance_template = google_compute_instance_template.test_template.id
  region            = var.region
  hostname          = var.network_prefix
  target_size       = 1
  named_ports = [{
    name = "http",
    port = 3000
    },
    {
      name = "http",
      port = 3001
    }
  ]
}


module "gce-lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google"
  name              = "module-load-balancer1"
  project           = var.project
  target_tags       = [var.network_prefix]
  firewall_networks = [var.network_prefix]

  backends = {
    default = {

      description                     = null
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      edge_security_policy            = null
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null
      compression_mode                = null

      health_check = {
        check_interval_sec  = 10
        timeout_sec         = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        port                = 3000
        port_specification  = "USE_FIXED_PORT"
        proxy_header        = "NONE"
        request_path        = "/"
        host                = null
        logging             = null
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group                        = module.mig.instance_group
          balancing_mode               = null
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        }
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
    }
  }
}