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
  VENV_STATE_FILE=$TASK_MASTER_HOME/state/venv.vars
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
  if [[ ! -f "$VENV_STATE_FILE" ]]
  then
    echo No state file found. Initializing state files...
    touch "$ROOT_STATE_FILE"
    mkdir -p "$ROOT_STATE_DIR"
  fi

  if [[ -z "$ARG_NAME" ]]
  then
    ARG_NAME=$(basename $TASK_DIR)
  fi

  ARG_NAME=${ARG_NAME//-/_}
  ENV_DIR=$ROOT_STATE_DIR/$ARG_NAME

  TTY=$( tty | tr -d '/' )
  . "$VENV_STATE_FILE"
}

venv_check_active() {
  if [[ "$VENV_ACTIVE" == "$TTY" ]]
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
  cd "$ENV_DIR"

  python3 -m venv "$ENV_DIR"

  echo "VENV_$ARG_NAME=\"$ENV_DIR\"" >> "$VENV_STATE_FILE"
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
  echo "PS1_$TTY=\"$PS1\"" >> "$VENV_STATE_FILE"
  echo "PATH_$TTY=\"$PATH\"" >> "$VENV_STATE_FILE"
  echo "VIRTUAL_ENV_$TTY=\"$VIRTUAL_ENV\"" >> "$VENV_STATE_FILE"

  _tmverbose_echo "Setting new env state..."
  echo "PS1_$TTY=\"$PS1\"" >> "$VENV_STATE_FILE"
  export_var "PS1" "(py-$ARG_NAME)-$PS1"
  source $ENV_DIR/bin/activate
  export_var "VIRTUAL_ENV" "$ENV_DIR/modules"
  export_var "PATH" "$PATH:$ENV_DIR/python/bin:$ENV_DIR/modules/bin"
  echo "VENV_ACTIVE=$TTY" >> $VENV_STATE_FILE

  set_trap "cd $RUNNING_DIR; task venv disable ;"
}

venv_disable() {
  if [[ -n "$VENV_ACTIVE" ]]
  then
    echo Disabling python environment...

    _tmverbose_echo "Removing saved variables..."
    awk "/^(PS1|PATH|VIRTUAL_ENV)_$TTY/ { next } /^VENV_ACTIVE=${TTY}$/ { next } { print }" "$VENV_STATE_FILE" > "$VENV_STATE_FILE.tmp"
    mv "$VENV_STATE_FILE"{.tmp,}

    _tmverbose_echo "Reseting env state..."
    val=PS1_$TTY
    export_var "PS1" "${!val}"
    val=PATH_$TTY
    export_var "PATH" "${!val}"
    val=VIRTUAL_ENV_$TTY
    export_var "VIRTUAL_ENV" "${!val}"

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
  awk "/^VENV_$ARG_NAME=/ { next } { print }" "$VENV_STATE_FILE" >> "$VENV_STATE_FILE.tmp"
  mv "$VENV_STATE_FILE"{.tmp,}
}

venv_list() {
  grep "VENV_" "$VENV_STATE_FILE" | sed 's/VENV_\(.*\)=.*/\1/'
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
