# Ansible instructions

## Installing Ansible in host machine

Here we will use Python to install and use Ansible. I'm managing it inside a anaconda environment, but you can use any Python environment you like.

```bash
pip install ansible-navigator
pip install ansible-builder
pip install ansible
pip install ansible-lint
```

And verify the installation:

```bash
ansible-navigator --version
ansible-builder --version
ansible --version
ansible-lint --version
```

For Docker installation, you can add the Ansible Docker role for easy installation and management of Docker in your hosts:

```bash
ansible-galaxy install geerlingguy.docker
```

## Creating Ansible inventory

Here you can follow to the inventory file to create your own inventory. I've created a simple one that separates the hosts in working groups, but this can be changed however you'd like.

to check the inventory file, you can use the following command:

```bash
ansible-inventory -i inventory.yaml --list
```

## Creating Ansible playbook

The playbooks have rules and tasks that will be executed in the hosts defined in the inventory file. You can create many playbooks for different purposes and groups, or a single very organized playbook that will do everything, separated by groups. It's up to you.

In this project, I've created a simple Linux VM setup playbook that will install some basic packages and do some basic configuration. You can check the playbook file to see what it does.

To run the playbook, you can use the following command:

```bash
ansible-playbook -i inventory.yaml playbook.yaml
```

or, if no ssh keys are set up, you can use:

```bash
ansible-playbook -i inventory.yml playbook.yml --ask-pass --ask-become-pass
```
