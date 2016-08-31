#!/bin/bash
#
# create new entry for password-store
#
# Usage: ./create.sh USERNAME URL

user="$1"
url="$2"

if [[ -z "$user" ]]
then
    echo "missing user"
    exit 1
fi

if [[ -z "$url" ]]
then
    echo "missing url"
    exit 1
fi

template="
user: $user
email: $user
date: $(date "+%d/%m/%Y")
type: web
url: $url
"

regexp='https?://([^/]+)'
site=${url}
if [[ "$url" =~ $regexp ]]
then
    site=${BASH_REMATCH[1]}
fi
# remove slashes
site=${site//\//}

entry=web/${user}-$site
echo "$(pwqgen)$template" | pass insert -m $entry
pass edit $entry

tmp=~/tmp/new_identity.txt
# catch email or user
pass show $entry | grep -E '^(email|user|date|url):' > $tmp 
identity="/home/sylvain/Notebooks/Notes/Home/identité.txt"

new_entry() {
    echo -e "\n===== $site ====="
    grep -E '^(email|date|url):' $tmp
    echo "''pass show $entry''"
}

tmp2=~/tmp/new_entry.txt
# merge
cat $identity <(new_entry) > $tmp2
mv $tmp2 $identity
rm -f $tmp $tmp2
