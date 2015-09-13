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
  # Fail fast and fail hard.
  set -e;

  # Paths.
  BUILD_DIR=#{ARGV[0]};
  export BUILD_DIR;

  # ## Build Time
  #

  # Switch to the repo's context.
  cd $BUILD_DIR;
  IM_LOCATION="/app/bin";

  # Install ImageMagick
  IM_VERSION="6.7.8-8";
  IM_URL="https://download-pixelapse.s3.amazonaws.com/im-$IM_VERSION.tar.gz";
  echo "Bundling ImageMagick version $IM_VERSION";
  curl --silent --max-time 60 --location "$IM_URL" | tar xz;

  # ufraw dependency
  UFRAW_VERSION="0.18";
  UFRAW_URL="https://download-pixelapse.s3.amazonaws.com/ufraw-bin-$UFRAW_VERSION.tar.gz";
  echo "Bundling ufraw version $UFRAW_VERSION";
  curl --silent --max-time 60 --location "$UFRAW_URL" | tar xz -C $IM_LOCATION;
  echo "Done bundling ImageMagick and ufraw.";
}
