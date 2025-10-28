# Mindapax Backend – Ansible Deployment

These playbooks provision a fresh OVH VPS (Ubuntu 22.04+) with Docker and deploy the Spring Boot backend alongside PostgreSQL containers.

## 1. Prerequisites
- Python 3.10+, Ansible 2.16+
- Access to the VPS via SSH (the default user is `ubuntu` for OVH images)
- `rsync` (used by `ansible.posix.synchronize`)

Install Ansible collections once:
```bash
cd infra/ansible
ansible-galaxy collection install -r requirements.yml
```

## 2. Inventory
Copy the example inventory, then set the VPS IP/DNS and SSH user:
```bash
cp inventory.example.ini inventory.ini
```

## 3. Secrets and configuration
Sensitive values live in an encrypted vault file:

```bash
cd infra/ansible/group_vars
cp backend.secrets.yml.example backend.secrets.yml
ansible-vault encrypt backend.secrets.yml
# then edit securely when needed
ansible-vault edit backend.secrets.yml   # fill DB, JWT, AWS, Zoom, OpenAI, etc.
```

To avoid prompts, store the password (with `chmod 600`) and export `ANSIBLE_VAULT_PASSWORD_FILE`:

```bash
echo 'strong-password-here' > ../../.ansible_vault_password
chmod 600 ../../.ansible_vault_password
export ANSIBLE_VAULT_PASSWORD_FILE=$(pwd)/../../.ansible_vault_password
```

You can still pass `--ask-vault-pass` if you prefer interactive entry.

## 4. Provision the server (one-time)
```bash
ansible-playbook -i inventory.ini provision-backend-docker.yml
```
This installs Docker Engine + Compose v2, configures UFW, and prepares `/opt/mindapax/docker` for runtime assets.

## 5. Deploy the application (Docker Compose)
```bash
./deploy-backend-vps.sh
# or
ansible-playbook -i inventory.ini deploy-backend-docker.yml
```
The playbook syncs the backend source as the Docker build context, builds the multi-stage image on the VPS, and brings up the PostgreSQL + Spring Boot containers under `docker compose`.

## 6. Managing updates
- Update secrets by re-running `provision-backend-docker.yml` after adjusting `group_vars` or environment exports.
- Redeploy on code changes: rerun `./deploy-backend-vps.sh` (Compose rebuilds the image).
- Logs: `sudo docker compose -f /opt/mindapax/docker/docker-compose.backend.yml logs -f backend`.
- Database dumps: use `docker exec` with `pg_dump` or schedule cron jobs on the host.

## 7. Optional hardening
- Attach a Cloudflare/AWS CloudFront CDN in front of the VPS.
- Add HTTPS termination with Nginx or Caddy (reverse proxy to `localhost:8080`).
- Automate backups: `pg_dump` to S3 and copy `/opt/mindapax/docker/mindapax-backend.env` to a secure vault.
