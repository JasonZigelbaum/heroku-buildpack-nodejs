needs_resolution() {
  local semver=$1
  if ! [[ "$semver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

install_nodejs() {
  local version="$1"
  local dir="$2"

  if needs_resolution "$version"; then
    echo "Resolving node version ${version:-(latest stable)} via semver.io..."
    local version=$(curl --silent --get --data-urlencode "range=${version}" https://semver.herokuapp.com/node/resolve)
  fi

  echo "Downloading and installing node $version..."
  local download_url="http://s3pository.heroku.com/node/v$version/node-v$version-$os-$cpu.tar.gz"
  curl "$download_url" --silent --fail -o /tmp/node.tar.gz || (echo "Unable to download node $version; does it exist?" && false)
  tar xzf /tmp/node.tar.gz -C /tmp
  mv /tmp/node-v$version-$os-$cpu/* $dir
  chmod +x $dir/bin/*
}

install_iojs() {
  local version="$1"
  local dir="$2"

  if needs_resolution "$version"; then
    echo "Resolving iojs version ${version:-(latest stable)} via semver.io..."
    version=$(curl --silent --get --data-urlencode "range=${version}" https://semver.herokuapp.com/iojs/resolve)
  fi

  echo "Downloading and installing iojs $version..."
  local download_url="https://iojs.org/dist/v$version/iojs-v$version-$os-$cpu.tar.gz"
  curl "$download_url" --silent --fail -o /tmp/node.tar.gz || (echo "Unable to download iojs $version; does it exist?" && false)
  tar xzf /tmp/node.tar.gz -C /tmp
  mv /tmp/iojs-v$version-$os-$cpu/* $dir
  chmod +x $dir/bin/*
}

install_npm() {
  local version="$1"

  if [ "$version" == "" ]; then
    echo "Using default npm version: `npm --version`"
  else
    if needs_resolution "$version"; then
      echo "Resolving npm version ${version} via semver.io..."
      version=$(curl --silent --get --data-urlencode "range=${version}" https://semver.herokuapp.com/npm/resolve)
    fi
    if [[ `npm --version` == "$version" ]]; then
      echo "npm `npm --version` already installed with node"
    else
      echo "Downloading and installing npm $version (replacing version `npm --version`)..."
      npm install --unsafe-perm --quiet -g npm@$version 2>&1 >/dev/null
    fi
  fi
}

install_imagemagick() {
  echo "Installing imagmagick"
  
  # Fail fast and fail hard.
  set -e

  # Prepend proper path for virtualenv hackery. This will be deprecated soon.
  export PATH=:/usr/local/bin:$PATH

  # Paths.
  BIN_DIR=$(cd $(dirname $0); pwd) # absolute path
  ROOT_DIR=$(dirname $BIN_DIR)
  BUILD_DIR=$1
  CACHE_DIR=$2

  # We'll need to send these statics to other scripts we `source`.
  # export PIP_DOWNLOAD_CACHE
  export BUILD_DIR

  # Syntax sugar.

  function puts-step (){
    echo "-----> $@"
  }

  # ## Build Time
  #

  # Switch to the repo's context.
  cd $BUILD_DIR

  IM_LOCATION="im"

  mkdir -p $IM_LOCATION

  # Install ImageMagick
  IM_VERSION="6.8.6-6"
  IM_URL="https://assets.tandemstock.com.s3.amazonaws.com/im-$IM_VERSION.tar.gz"
  puts-step "Bundling ImageMagick version $IM_VERSION"
  curl --silent --max-time 120 --location "$IM_URL" | tar xz

  # Install GraphicsMagick
  GM_VERSION="1.3.18"
  GM_URL="https://assets.tandemstock.com.s3.amazonaws.com/GraphicsMagick-$GM_VERSION.tar.gz"
  puts-step "Bundling GraphicsMagick version $GM_VERSION"
  curl --silent --max-time 120 --location "$GM_URL" | tar xz

  # ufraw dependency
  UFRAW_VERSION="0.19"
  UFRAW_URL="https://assets.tandemstock.com.s3.amazonaws.com/ufraw-0.19.tar.gz"
  puts-step "Bundling ufraw version $UFRAW_VERSION"
  curl --silent --max-time 60 --location "$UFRAW_URL" | tar xz -C $IM_LOCATION

  export PATH=:/app/im/bin:/local/bin:$PATH
}
