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

### Run


#### Verify

```
./provision.sh -k
```


#### Configure workers


```
./provision.sh -c
```

#### Add workers

  1. Fill in Rancher Server address, token and cluster name into `provision.sh`:  
     ![image](https://user-images.githubusercontent.com/977107/141729683-864b1f10-709b-4d95-a2ed-d6e3e537f987.png)
  3. Add workers to cluster:
     ```
     ./provision.sh -a
     ```
