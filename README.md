**Status:** In progress...

# Loki, Grafana, and Django Logging Stack

A simple setup to collect, store, and visualize Docker logs using Loki, Grafana, and Promtail, with a Django backend emitting structured logs.

## Features

- **Grafana** for dashboards and log visualization
- **Loki** for log aggregation and storage
- **Promtail** for collecting Docker container logs
- **Django backend** with logs formatted for Loki/Grafana
- **Docker Compose** for easy orchestration
- **Vagrant** for VM-based deployment **if Docker is not available on your host / if your user is not allowed to read docker.sock**

## Architecture

```
+----------------+      +----------------+      +----------------+
|   Django App   | ---> |    Promtail    | ---> |      Loki      |
| (Dockerized)   |      | (Dockerized)   |      |  (Dockerized)  |
+----------------+      +----------------+      +----------------+
        |                                                    |
        +--------------------> Grafana <---------------------+
                          (Dashboards & Log Queries)
```

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Vagrant](https://www.vagrantup.com/) (optional, for VM deployment)
- [VirtualBox](https://www.virtualbox.org/) (if using Vagrant)

### Usage

#### Local Docker Deployment

1. **Start the stack:**
   ```sh
   make up
   ```
2. **Stop the stack:**
   ```sh
   make down
   ```
3. **Clean up resources:**
   ```sh
   make clean
   ```

#### VM Deployment (if you can't access Docker on your host)

1. **Start the VM and stack:**

   ```sh
   vagrant up
   ```

   - The VM will be accessible at `192.168.56.110`.
   - Grafana: [http://192.168.56.110:3000](http://192.168.56.110:3000)
   - Django: [http://192.168.56.110:8000](http://192.168.56.110:8000)
2. **SSH into the VM:**

   ```sh
   vagrant ssh <your_username>VM
   ```
3. **Destroy the VM:**

   ```sh
   vagrant destroy
   ```

#### Shared Folders

- The project folder is shared between your host and the VM at `/vagrant`.

## Project Structure

- `backend/` - Django application (logs to stdout in Loki-compatible format)
- `grafana/` - Grafana provisioning (dashboards, datasources)
- `loki/` - Loki configuration
- `promtail/` - Promtail configuration for Docker log scraping
- `docker-compose.yaml` - Orchestration for all services
- `Vagrantfile`, `VMSetup.sh` - VM provisioning scripts

## Logging

- Django logs are structured for Loki/Grafana and sent to stdout.
- Promtail collects logs from all Docker containers and forwards them to Loki.
- Grafana dashboards are pre-provisioned for log exploration.

## Credentials

- **Grafana default login:**
  - Username: `admin`
  - Password: `admin` (unless changed)

## References

- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Django Documentation](https://docs.djangoproject.com/)
