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

PLUGINS_LOAD="$SCRIPTDIR/plugins/load.sh"
if [[ -e "$PLUGINS_LOAD" ]]
then
  source $PLUGINS_LOAD
  for p in $PLUGINS
  do
    source $p
  done
fi

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

  if [[ -n "$OVH_EMAIL" ]]
  then
    # checkovh email
    if ! check_ovh_email "$email"
    then
      create_ovh_email "$email"
    fi
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
  if [[ $r -eq 0 ]]
  then
    echo "created OK $ENTRY"
  fi
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
  if [[ -n "$OVH_EMAIL" ]]
  then
    if ! ovh_test_login
    then
      ovh_login || { echo "login error" ; exit 1; }
    fi
  fi

  if create_password_entry $1 "$2"
  then
    # succes
    if [[ -n "$ZIM_WIKI" ]]
    then
      update_identity_zim_wiki
    fi
  fi
}

if [[ $sourced -eq 0  ]] ; then
  create_main "$@"
fi
