# Modules and Drivers for Bash Task Master

This is an example repository to hold external modules and drivers for bash task master.

## Usage

1\. Update the $TASK_MASTER_HOME/config.sh
```
  TASK_REPOS="https://raw.github.usercontent.com/hppr-dev/btm-extra/main/inventory"
```

2. Run `task global module --enable MODULE_ID` to install enable the module ID

## Modules in this repo

### todo

A simple todo application to keep track of todos for a project

### venv

A module to manage python virtual environments in bash task master.

### gonv

A module to manage go environments in bash task master

## Inventory file

The inventory file is a simple key value text file that enumerates the available modules.

There are two required keys:

  * MODULE_DIR - the relative location where the module files are stored
  * DRIVER_DIR - the relative location where the driver files are stored

These keys are relative to the directory where the inventory file is stored.

Every other key in the file should either be prefixed with module- or driver-.
Each module- key points to a module file in the MODULE_DIR and each driver- key points to a driver file in the DRIVER_DIR.
Every non whitespace character after module- or driver- in the key is considered the ID.
The ID can be used to install and enable modules or drivers in a local bash task master installation.
