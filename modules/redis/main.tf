# =============================================================================
# Redis VM Instance
# =============================================================================

resource "google_compute_instance" "redis" {
  name         = "${var.project_name}-redis-${var.name}"
  project      = var.project_id
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    access_config {
      # Ephemeral external IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Update system and install Redis
    apt-get update
    apt-get install -y redis-server

    # Configure Redis
    cat > /etc/redis/redis.conf <<'REDIS_CONF'
    # Basic configuration
    bind 0.0.0.0
    port 6379
    daemonize yes
    pidfile /var/run/redis/redis-server.pid

    # Security
    requirepass ${var.redis_password}

    # Persistence
    save 900 1
    save 300 10
    save 60 10000
    dir /var/lib/redis

    # Memory management
    maxmemory 256mb
    maxmemory-policy allkeys-lru

    # Logging
    loglevel notice
    logfile /var/log/redis/redis-server.log

    # Network
    tcp-keepalive 300
    timeout 0
    REDIS_CONF

    # Create required directories
    mkdir -p /var/run/redis /var/log/redis
    chown redis:redis /var/run/redis /var/log/redis

    # Restart Redis with new configuration
    systemctl restart redis-server
    systemctl enable redis-server

    # Verify Redis is running
    sleep 2
    redis-cli -a '${var.redis_password}' ping
  EOF

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  tags = ["redis"]

  labels = merge(var.labels, {
    component = "redis"
    instance  = var.name
  })

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  scheduling {
    preemptible       = false
    automatic_restart = true
  }

  allow_stopping_for_update = true
}
