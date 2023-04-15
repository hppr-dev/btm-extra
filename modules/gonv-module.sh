arguments_gonv() {
  SUBCOMMANDS="init|enable|disable|list|destroy|vs"
  INIT_DESCRIPTION="Initialize a new go environment"
  INIT_OPTIONS="version:v:str name:n:str platform:p:str"
  ENABLE_DESCRIPTION="Enable a go environment"
  ENABLE_OPTIONS="name:n:str"
  DISABLE_DESCRIPTION="Disable current go environment"
  DESTROY_DESCRIPTION="Remove go environment"
  DESTROY_OPTIONS="name:n:str"
  LIST_DESCRIPTION="List go environments"
  VS_DESCRIPTION="Set vscode environment"
  VS_REQUIREMENTS="name:n:str"
}

task_gonv() {
  #See https://golang.org/dl/ for available versions/platforms
  DEFAULT_VERSION=1.19
  DEFAULT_PLATFORM=linux-amd64
  ROOT_STATE_DIR=$TASK_MASTER_HOME/state/gonv
  GO_DOWNLOAD_CACHE=$ROOT_STATE_DIR/downloads

  gonv_load_vars
  case $TASK_SUBCOMMAND in
    "init")
    gonv_init
    ;;
    "enable")
    gonv_enable
    ;;
    "disable")
    gonv_disable
    ;;
    "destroy")
    gonv_destroy
    ;;
    "list")
    gonv_list
    ;;
    "vs")
    gonv_vs
    ;;
  esac
}

gonv_load_vars() {
  if [[ -z "$ARG_NAME" ]]
  then
    ARG_NAME=$(basename "$TASK_DIR")
  fi
  ARG_NAME=${ARG_NAME/-/_}

  ENV_DIR=$ROOT_STATE_DIR/$ARG_NAME
  TTY=$(tty | tr -d '/' )

  local_name=GONV_ACTIVE_$TTY
  LOCAL_GONV_ACTIVE=${!local_name}
}

gonv_check_active() {
  if [[ -n "$LOCAL_GONV_ACTIVE" ]]
  then
    echo "A go environment is already active. Cannot $TASK_SUBCOMMAND."
    exit 1
  fi
}

gonv_check_exists() {
  val=GONV_$ARG_NAME
  if [[ -z "${!val}" ]]
  then
    return 1
  fi
  return 0
}

gonv_init() {

  if gonv_check_exists
  then
    echo gonv $ARG_NAME already exists. Did you mean enable?
    exit 1
  fi

  if [[ -z "$ARG_VERSION" ]]
  then
    ARG_VERSION=$DEFAULT_VERSION
  fi

  if [[ -z "$ARG_PLATFORM" ]]
  then
    ARG_PLATFORM=$DEFAULT_PLATFORM
  fi

  echo Initializing go $ARG_VERSION environment in $ENV_DIR...
  mkdir -p $ENV_DIR/modules $GO_DOWNLOAD_CACHE
  cd $ENV_DIR

  echo Retrieving go assets...
  GO_TAR=go$ARG_VERSION.$ARG_PLATFORM.tar.gz
  if [[ ! -f "$GO_DOWNLOAD_CACHE/$GO_TAR" ]]
  then
    echo go $ARG_VERSION not found locally. Downloading...
    curl -L -o "$GO_DOWNLOAD_CACHE/$GO_TAR" "https://golang.org/dl/$GO_TAR"
  fi

  echo Extracting go assets...
  cp "$GO_DOWNLOAD_CACHE/$GO_TAR" .
  tar -xf "$GO_TAR"
  rm "$GO_TAR"

  echo Saving gonv record...
  persist_module_var "GONV_$ARG_NAME" "$ENV_DIR"
}

gonv_enable() {
  if ! gonv_check_exists
  then
    echo gonv $ARG_NAME does not exist. Did you mean init?
    exit 1
  fi

  gonv_check_active
  echo Enabling go environment $ARG_NAME


  _tmverbose_echo "Saving current env variables..."

  eval "PS1_$TTY=$PS1"
  eval "PATH_$TTY=$PATH"
  eval "GOPATH_$TTY=$GOPATH"

  hold_module_var "PS1_$TTY"
  hold_module_var "PATH_$TTY"
  hold_module_var "GOPATH_$TTY"

  _tmverbose_echo "Updating env variables..."
  export_var "PS1" "(go-$ARG_NAME)-$PS1"
  export_var "GOPATH" "$ENV_DIR/modules"
  export_var "PATH" "$PATH:$ENV_DIR/go/bin:$ENV_DIR/modules/bin"
  persist_module_var "GONV_ACTIVE_$TTY" "TRUE"

  set_trap "cd $RUNNING_DIR; task gonv disable ;"
}

gonv_disable() {
  if [[ -n "$LOCAL_GONV_ACTIVE" ]]
  then
    echo Disabling go environment
    _tmverbose_echo "Removing saved env variables..."
    remove_module_var "GONV_ACTIVE_$TTY"

    _tmverbose_echo "Extracting saved env variables..."
    release_module_var "PS1_$TTY"
    release_module_var "PATH_$TTY"
    release_module_var "GOPATH_$TTY"

    unset_trap
  else
    echo Go environment not active
  fi
}

gonv_destroy() {

  if ! gonv_check_exists
  then
    echo gonv $ARG_NAME does not exist.
    exit 1
  fi

  gonv_check_active
  echo Destroying go environment

  echo Removing $ENV_DIR...
  if [[ -d "$ENV_DIR" ]]
  then
   chmod -R +w $ENV_DIR/
   rm -r $ENV_DIR
  fi

  echo Removing gonv record...
  remove_module_var "GONV_$ARG_NAME"
}

gonv_list() {
  grep "GONV_" "$MODULE_STATE_FILE" | sed 's/GONV_\(.*\)=.*/\1/'
}

gonv_vs() {
  if gonv_check_exists
  then
    ln -sf "$ENV_DIR" "$TASK_MASTER_HOME/state/gonv/vscode"
    echo "Set $ARG_NAME as $TASK_MASTER_HOME/state/gonv/vscode."
  else
    echo "gonv $ARG_NAME does not exist"
  fi
}
  


readonly -f arguments_gonv
readonly -f task_gonv
readonly -f gonv_load_vars
readonly -f gonv_check_active
readonly -f gonv_check_exists
readonly -f gonv_init
readonly -f gonv_enable
readonly -f gonv_disable
readonly -f gonv_destroy
readonly -f gonv_list
readonly -f gonv_vs
