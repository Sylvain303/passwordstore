#!/bin/bash
#
# ovh_email alias manage for create.sh
#
# requires:
# - https://github.com/yadutaf/ovh-cli
# - https://github.com/opensource-expert/ovh-tools
# - apt install jq

OVH_EMAIL=true
OVH_CLIDIR=$HOME/code/ovh/ovh-cli

ovh_cli() {
  cd $OVH_CLIDIR
  ./ovh-eu "$@"
  local r=$?
  cd - > /dev/null
  return $r
}

ovh_login() {
  cd $OVH_CLIDIR/../ovh-tools
  ./mk_cred.py update
  local r=$?
  cd - > /dev/null
  return $r
}

ovh_test_login() {
  local r=$(ovh_cli --format json auth current-credential)
  local regexp="^This credential (is not valid|does not exist)"
  if [[ "$r" =~ $regexp ]]
  then
    return 1
  fi

  if [[ "$(echo "$r" | jq -r '.status')" == 'expired' ]]
  then
    return 1
  fi
}

show_ovh_alias() {
  email=$1
  domain=${email#*@}
  ovh_cli \
    email-domain $domain redirection --from "$email" \
    | grep --color $email
  return $?
}

check_ovh_email() {
  email=$1
  ovh_cli \
    email-domain ledragon.net redirection --from "$email" \
    | grep -q "$email"
  return $?
}

create_ovh_email() {
  email=$1
  domain=${email#*@}

  if grep -l -q "^$domain$" domain_managed.txt
  then
    ovh_cli email-domain $domain redirection post \
        --from $email \
        --to postmaster@ledragon.net \
        --localCopy no
    return $?
  else
    return 0
  fi
}

remove_ovh_email() {
  email=$1
  domain=${email#*@}
  id=$(show_ovh_alias $email | awk '{print $4}')

  echo "id=$id"
  if [[ ! -z "$id" ]]
  then
    ovh_cli email-domain ${domain} redirection ${id} delete
  fi
}
