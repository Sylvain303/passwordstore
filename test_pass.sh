#!/bin/bash
#

IFS=$'\n'
touch tested
for f in $(find ~/.password-store/ -type f -name \*.gpg)
do
    if grep -q "$f" tested
    then
        continue
    fi

    if ! gpg -q --batch -d "$f" > /dev/null
    then
        echo "$f"
    else
        echo "$f" >> tested
    fi
done
