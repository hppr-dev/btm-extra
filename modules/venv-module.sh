arguments_venv() {
  SUBCOMMANDS="init|enable|disable|list|destroy"
  INIT_DESCRIPTION="Initialize a new python environment"
  INIT_OPTIONS="version:v:str name:n:str platform:p:str"
  ENABLE_DESCRIPTION="Enable a python environment"
  ENABLE_OPTIONS="name:n:str"
  DISABLE_DESCRIPTION="Disable current python environment"
  DESTROY_DESCRIPTION="Remove python environment"
  DESTROY_OPTIONS="name:n:str"
  LIST_DESCRIPTION="List python environments"
}

task_venv() {
  ROOT_STATE_DIR=$TASK_MASTER_HOME/state/venv
  venv_load_vars
  case $TASK_SUBCOMMAND in
    "init")
    venv_init
    ;;
    "enable")
    venv_enable
    ;;
    "disable")
    venv_disable
    ;;
    "destroy")
    venv_destroy
    ;;
    "list")
    venv_list
    ;;
  esac
}

venv_load_vars() {
  if [[ -z "$ARG_NAME" ]]
  then
    ARG_NAME=$(basename "$TASK_DIR")
  fi

  ARG_NAME=${ARG_NAME//-/_}
  ENV_DIR=$ROOT_STATE_DIR/$ARG_NAME

  TTY=$( tty | tr -d '/' )
  local_name=VENV_ACTIVE_$TTY
  LOCAL_VENV_ACTIVE=${!local_name}
}

venv_check_active() {
  if [[ "$LOCAL_VENV_ACTIVE" ]]
  then
    echo "A python environment is already active. Cannot $TASK_SUBCOMMAND."
    exit 1
  fi
}

venv_check_exists() {
  val=VENV_$ARG_NAME
  if [[ -z "${!val}" ]]
  then
    return 1
  fi
  return 0
}

venv_init() {

  if venv_check_exists
  then 
    echo venv $ARG_NAME already exists. did you mean enable?
    exit 1
  fi

  venv_check_active 

  echo Initializing python $ARG_VERSION environment in $ENV_DIR

  mkdir -p "$ENV_DIR"
  cd "$ENV_DIR" || exit

  python3 -m venv "$ENV_DIR"

  persist_module_var "VENV_$ARG_NAME" "$ENV_DIR"
}

venv_enable() {
  if ! venv_check_exists
  then 
    echo venv $ARG_NAME does not exist. did you mean init?
    exit 1
  fi

  venv_check_active

  echo Enabling python environment $ARG_NAME

  _tmverbose_echo "Saving current env state..."
  persist_module_var "PS1_$TTY" "$PS1"
  persist_module_var "PATH_$TTY" "$PATH"
  persist_module_var "VIRTUAL_ENV_$TTY" "$VIRTUAL_ENV"

  _tmverbose_echo "Setting new env state..."

  export_var "PS1" "(py-$ARG_NAME)-$PS1"
  source $ENV_DIR/bin/activate
  export_var "VIRTUAL_ENV" "$ENV_DIR/modules"
  export_var "PATH" "$PATH:$ENV_DIR/python/bin:$ENV_DIR/modules/bin"
  persist_module_var "VENV_ACTIVE_$TTY" "TRUE"

  set_trap "cd $RUNNING_DIR; task venv disable ;"
}

venv_disable() {
  if [[ -n "$LOCAL_VENV_ACTIVE" ]]
  then
    echo Disabling python environment...

    _tmverbose_echo "Removing saved variables..."
    remove_module_var "VENV_ACTIVE_$TTY"

    _tmverbose_echo "Reseting env state..."
    ps1_var=PS1_$TTY
    path_var=PATH_$TTY
    ve_var=VIRTUAL_ENV_$TTY

    export_var "PS1" "${!ps1_var}"
    export_var "PATH" "${!path_var}"
    export_var "VIRTUAL_ENV" "${!ve_var}"
    remove_module_var "$ps1_var"
    remove_module_var "$path_var"
    remove_module_var "$ve_var"

    unset_trap
  else
    echo Python environment not active
  fi
}

venv_destroy() {
  if ! venv_check_exists
  then 
    echo venv $ARG_NAME does not exist.
    exit 1
  fi

  venv_check_active
  echo Destroying python environment

  echo Removing $ENV_DIR...
  if [[ -d "$ENV_DIR" ]]
  then
   chmod -R +w $ENV_DIR/
   rm -r $ENV_DIR
  fi

  echo Removing $ARG_NAME record...
  remove_module_var "VENV_$ARG_NAME"
}

venv_list() {
  grep "VENV_" "$MODULE_STATE_FILE" | sed 's/VENV_\(.*\)=.*/\1/'
}


readonly -f arguments_venv
readonly -f task_venv
readonly -f venv_load_vars
readonly -f venv_check_active
readonly -f venv_check_exists
readonly -f venv_init
readonly -f venv_enable
readonly -f venv_disable
readonly -f venv_destroy
readonly -f venv_list
