log_info() {
  #echo "`date +\"%M:%S\"`  $*"
  echo "PBS:   $*"
}

indent() {
  while read LINE; do
    echo "       $LINE" || true
  done
}

log_major() {
  echo ""
  echo "Phoenix Buildpack Static"
  echo "-----> $*"
}

file_contents() {
  if test -f $1; then
    echo "$(cat $1)"
  else
    echo ""
  fi
}

load_config() {
  log_info "Loading config..."

  local custom_config_file="${build_dir}/phoenix_static_buildpack.config"

  # Source for default versions file from buildpack first
  source "${build_pack_dir}/phoenix_static_buildpack.config"

  if [ -f $custom_config_file ]; then
    source $custom_config_file
  else
    log_info "WARNING: phoenix_static_buildpack.config wasn't found in the app"
    log_info "Using default config from Phoenix static buildpack"
  fi

  phoenix_dir=$build_dir/$phoenix_relative_path

  log_info "Detecting assets directory"
  if [ -f "$phoenix_dir/$assets_path/package.json" ]; then
    # Check phoenix custom sub-directory for package.json
    log_info "* package.json found in custom directory"
  elif [ -f "$phoenix_dir/package.json" ]; then
    # Check phoenix root directory for package.json, phoenix 1.2.x and prior
    log_info "WARNING: package.json detected in root "
    log_info "* assuming phoenix 1.2.x or prior, please check config file"

    assets_path=.
    phoenix_ex=phoenix
  else
    # Check phoenix custom sub-directory for package.json, phoenix 1.3.x and later
    log_info "WARNING: no package.json detected in root nor custom directory"
    log_info "* assuming phoenix 1.3.x and later, please check config file"

    assets_path=assets
    phoenix_ex=phx
  fi

  assets_dir=$phoenix_dir/$assets_path
  log_info "Will use phoenix configuration:"
  log_info "* assets path ${assets_path}"
  log_info "* mix tasks namespace ${phoenix_ex}"

  log_info "Will use the following versions:"
  log_info "* Node ${node_version}"
}

export_config_vars() {
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
  if [ -d "$env_dir" ]; then
    log_info "Will export the following config vars:"
    for e in $(ls $env_dir); do
      echo "$e" | grep -E "$whitelist_regex" | grep -vE "$blacklist_regex" &&
      export "$e=$(cat $env_dir/$e)"
      :
    done
  fi
}

export_mix_env() {
  if [ -z "${MIX_ENV}" ]; then
    if [ -d $env_dir ] && [ -f $env_dir/MIX_ENV ]; then
      export MIX_ENV=$(cat $env_dir/MIX_ENV)
    else
      export MIX_ENV=prod
    fi
  fi

  log_info "* MIX_ENV=${MIX_ENV}"
}
