### Status: In progress...

# Loki + Grafana + Vault Secure Stack

This project provides a secure, containerized observability stack using **Loki** for log aggregation, **Grafana** for visualization, and **HashiCorp Vault** for secrets management. All services are orchestrated with Docker Compose and communicate over TLS with certificates generated at runtime.

---

## Stack

- **Loki**: Log aggregation and storage.
- **Grafana**: Visualization and dashboards, with secrets (like admin/user passwords) securely fetched from Vault at startup.
- **Vault (Raft HA)**: Secure storage and distribution of secrets, with TLS enabled and automatic initialization/unsealing.
- **Promtail**: Log shipping from Docker containers to Loki.
- **Automated Certificate Generation**: Self-signed CA and per-service certificates generated on container startup.
- **Secure Secret Sharing**: Grafana retrieves credentials from Vault using a read-only token, never exposing secrets in images or environment variables.

1. **Access the services:**

   - **Grafana**: [http://localhost:3000](http://localhost:3000)
   - **Vault UI**: [https://localhost:8201](https://localhost:8201) (self-signed cert, ignore browser warning)
   - **Loki**: [http://localhost:3100](http://localhost:3100)
   - **Django** (useless): [http://localhost:8000](http://localhost:8000)

---

Include a Vagrantfile to deploy a VM locally and start the project

1. IP: 192.168.56.110
