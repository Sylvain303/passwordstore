#!/bin/bash
#
# create new entry for password-store
#
# Usage: ./create.sh USERNAME URL
#

[[ $0 != "$BASH_SOURCE" ]] && sourced=1 || sourced=0
if [[ $sourced -eq 0  ]]
then
  ME=$(readlink -f $0)
else
  ME=$(readlink -f "$BASH_SOURCE")
fi
SCRIPTDIR=$(dirname $ME)
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

create_password_entry() {
  email="$1"
  url="$2"

  if [[ -z "$email" ]]
  then
      echo "missing email"
      exit 1
  fi

  if [[ -z "$url" ]]
  then
      echo "missing url"
      exit 1
  fi

  # checkovh email
  if ! check_ovh_email "$email"
  then
    create_ovh_email "$email"
  fi

  template="
user: $email
email: $email
date: $(date "+%d/%m/%Y")
type: web
url: $url
"

  regexp='https?://([^/]+)'
  SITE=${url}
  if [[ "$url" =~ $regexp ]]
  then
      SITE=${BASH_REMATCH[1]}
  fi
  # remove slashes
  SITE=${SITE//\//}

  ENTRY=web/$SITE
  echo "$(pwqgen)$template" | pass insert -m $ENTRY
  pass edit $ENTRY
  # file exists + size > 0
  test -s ~/.password-store/$ENTRY.gpg
  r=$?
  echo $r
  return $r
}

# need globals: $ENTRY, $SITE and $TMP
# TMP set by update_identity_zim_wiki()
# other by create_password_entry()
new_zim_entry() {
  echo -e "\n===== $SITE ====="
  grep -E '^(email|date|url):' $TMP
  echo "''pass show $ENTRY''"
}

update_identity_zim_wiki() {
  TMP=~/tmp/new_identity.txt
  # catch email or user
  pass show $ENTRY | grep -E '^(email|user|date|url):' > $TMP
  identity="/home/sylvain/Notebooks/Notes/Home/identité.txt"
  tmp2=~/tmp/new_entry.txt
  # merge into $tmp2
  cat $identity <(new_zim_entry) > $tmp2
  diff -u $identity $tmp2
  mv $tmp2 $identity &&  echo "$identity updated + $SITE"
  # cleanup
  rm -f $TMP $tmp2
  # debug
  #echo $TMP
}

create_main() {
  if ! ovh_test_login
  then
    ovh_login || { echo "login error" ; exit 1; }
  fi

  if create_password_entry $1 "$2"
  then
    update_identity_zim_wiki
  fi
}

if [[ $sourced -eq 0  ]] ; then
  create_main "$@"
fi
