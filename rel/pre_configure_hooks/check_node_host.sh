NODE_HOST_DEFAULT="127.0.0.1"

if [[ -z "$NODE_HOST" ]]; then
  notice "NODE_HOST not set, defaults to ${NODE_HOST_DEFAULT}. Consider setting NODE_HOST to the machine's hostname or IP, as seen by others in the network."
  export NODE_HOST="${NODE_HOST_DEFAULT}"
fi

if [[ -z "$NODE_COOKIE" ]]; then
  export NODE_COOKIE="$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
  notice "NODE_COOKIE not set; randomly generated to ${NODE_COOKIE}"
fi

export REPLACE_OS_VARS=true
