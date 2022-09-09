# Shellcheck driver
# Adds shellcheck to validation step
# tasks_file_name = tasksc.sh
# setup = shellcheck/setup.sh

source $DRIVER_DIR/bash_driver.sh

DRIVER_VALIDATE_TASKS_FILE="shellcheck -s bash -e SC2034"
