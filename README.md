# systemd-deploy

Remote handling a systemd service with git deploy functionality. Great for persisting node processes.

## Usage

Create `.env` and `<service name>.service` files from templates.

```console
# Git deploy
systemd-deploy/deploy.sh

# Update the systemd service
systemd-deploy/deploy.sh systemd_activate
```
