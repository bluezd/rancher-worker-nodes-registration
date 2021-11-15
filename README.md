# Rancher Worker Node Provision Script

## Intro

This is a script for provision/registering rancher worker nodes automatically. 

## Usage

### Ansible Verification

```
cd ansible
```

```
ansible -i xlsx_inventory.py k8s-worker -m ping
ansible -i xlsx_inventory.py k8s-worker --become-method su --become-user sysop -b -a "sudo systemctl status sshd"
```
