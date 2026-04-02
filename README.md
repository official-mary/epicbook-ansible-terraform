# The EpicBook Infrastructure & Deployment
This repository contains the full Infrastructure as Code (IaC) and Configuration Management to deploy the EpicBook application on AWS using Terraform and Ansible.


---
Epicbook is A Node.js bookstore web application deployed on AWS using Terraform for infrastructure provisioning and Ansible for configuration management.

The project is split into two main phases:

Terraform (Provisioning): Creates the VPC, EC2 instance (Web Server), and RDS instance (MySQL Database). It automatically generates the ansible/inventory.ini file using template outputs.

Ansible (Configuration): Configures the EC2 instance, installs Nginx, clones the app, and connects it to the RDS database using encrypted secrets.

---
 Components
1. Terraform (Infrastructure)
Located in terraform/aws/.

Dynamic Inventory: Terraform uses a local_file resource to inject the EC2 Public IP and the RDS Endpoint directly into ansible/inventory.ini.

Security: Passwords are managed via terraform.tfvars (ignored by Git).

2. Ansible (Deployment)
Located in ansible/.
The deployment is managed by site.yml which executes three main stages:

Common: System updates and basic dependencies.

Nginx: Reverses proxy setup to serve the Node.js app on port 80.

EpicBook: Clones the repo, installs npm packages, and seeds the RDS database.

---
 Security & Secrets
I use Ansible Vault to protect sensitive data.

Vault File: ansible/group_vars/web/vault.yml (Encrypted).

Password File: .vault_pass (Local only, ignored by Git).

Note: The database password must be alphanumeric. Special characters like @ are restricted to ensure compatibility with AWS RDS CLI parameters.
A .vault_pass file in the root directory.


---

## Tech Stack

| Layer | Technology |
|---|---|
| Application | Node.js + Express |
| Database | MySQL (bookstore) |
| Web Server | Nginx (reverse proxy) |
| Process Manager | PM2 |
| Infrastructure | AWS EC2 (Terraform) |
| Configuration | Ansible |

---

## Project Structure
```
epicbook-prod/
├── ansible/
│   ├── ansible.cfg
│   ├── inventory.ini.example
│   ├── site.yml
│   ├── group_vars/
│   │   └── web/
│   │       ├── main.yml        # Non-sensitive variables
│   │       └── vault.yml       # Encrypted secrets (Ansible Vault)
│   └── roles/
│       ├── common/             # Base system setup
│       ├── epicbook/           # App deployment
│       │   ├── tasks/main.yml
│       │   └── handlers/main.yml
│       └── nginx/              # Nginx configuration
│           ├── tasks/main.yml
│           ├── handlers/main.yml
│           └── templates/
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── providers.tf
```

---

## Prerequisites

- Ansible installed on your local machine
- Terraform installed on your local machine
- AWS account with appropriate IAM permissions
- SSH key pair for EC2 access

---

## Deployment Guide

### 1. Clone the repo
```bash
git clone my repo
cd epicbook-ansible-terraform
cd terraform/aws
```

### 2. Provision Infrastructure with Terraform
```bash
terraform init
terraform plan
terraform apply
```
Note the output EC2 public IP address
And rds endpoint.(Though it will be automatically injected into the inventory.ini)

### 3. Set up Ansible inventory
```bash
cd ../ansible
cp inventory.ini.example inventory.ini
```
Edit `inventory.ini` and fill in your server IP and SSH key path: (This is done automatically)

```ini
[web]
<YOUR_EC2_IP>

[web:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/<YOUR_KEY>
ansible_python_interpreter=/usr/bin/python3
```

### 4. Set up Ansible Vault secrets
Create your vault file:
```bash
cat > group_vars/web/vault.yml << 'VAULT'
---
mysql_root_password: "your_root_password"
db_password: "your_app_db_password"
VAULT
```
Encrypt it:
```bash
ansible-vault encrypt group_vars/web/vault.yml
```
Create your vault password file (never committed):
```bash
echo "your_vault_password" > .vault_pass
```

### 5. Deploy the application
```bash
ansible-playbook -i inventory.ini site.yml
```

### 6. Access the app
Open your browser at:
```
http://<YOUR_EC2_IP>
```

---

## Configuration Variables

### `group_vars/web/main.yml` (non-sensitive)

| Variable | Description | Default |
|---|---|---|
| `app_repo` | GitHub repo URL | theepicbook.git |
| `app_dest` | App directory on server | /var/www/epicbook |
| `app_user` | App user | www-data |
| `app_group` | App group | www-data |
| `nginx_site_name` | Nginx site name | epicbook |
| `app_port` | App port | 3000 |
| `db_user` | Database app user | epicbook_user |
| `db_name` | Database name | bookstore |

### `group_vars/web/vault.yml` (encrypted)

| Variable | Description |
|---|---|
| `mysql_root_password` | MySQL root password |
| `db_password` | App database user password |

---

## What Ansible Does

1. Creates app directory
2. Clones the repo from GitHub
3. Installs Node.js, npm, and MySQL
4. Sets MySQL root password securely
5. Creates the bookstore database and app user
6. Runs schema and seed SQL files
7. Installs app dependencies via npm
8. Creates `.env` file with DB credentials
9. Installs and configures PM2
10. Configures Nginx as reverse proxy
11. Sets up PM2 to survive server reboots

---

## Security Notes

- Secrets are encrypted using Ansible Vault
- `.vault_pass` and `inventory.ini` are never committed
- App connects to MySQL via a dedicated user (not root)
- `.env` file has restricted permissions (0640)

---

## Re-running the Playbook

The playbook is **idempotent** — safe to run multiple times:
- Database is only created if it doesn't exist
- Seeds only run if tables don't exist
- PM2 restarts the app cleanly on each run
```bash
ansible-playbook -i inventory.ini site.yml
```

---

## Author
Ogbonna Nwanneka Mary