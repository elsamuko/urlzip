#!/usr/bin/env bash

# check for GNU base64 with wrap option
base64 --help 2>&1 | grep GNU > /dev/null || { echo "Error: Could not find GNU grep"; exit 1; }

if [ ! -f "$1" ]
then
    echo "Usage: $(basename "$0") <file>"
    exit 1
fi

WDIR="/tmp/urlzip"
ORIG="$1"
EXT=${ORIG##*.}
ZIP="$WDIR/${ORIG%$EXT}zip"
B64="$WDIR/${ORIG%$EXT}b64"
BACKUP="$WDIR/${ORIG%$EXT}copy.$EXT"

echo "ORIG   : [$ORIG]"
echo "EXT    : [$EXT]"
echo "ZIP    : [$ZIP]"
echo "B64    : [$B64]"
echo "BACKUP : [$BACKUP]"

function doPrepare {
    if [ -d "$WDIR" ]; then
        rm -rf "$WDIR"
    fi
    mkdir -p "$WDIR"
}

function doCompress {
    echo
    echo
    echo "COMPRESS"

    for LINE in $(base64 -w 1000 "$ORIG")
    do
        TINY=$(curl -s "http://tinyurl.com/api-create.php?url=$LINE" | grep -Po "(?<=http://tinyurl.com/).*" )
        echo "TINY   : [$TINY]"

        echo "$TINY" >> "$ZIP"

        # workaround for quotas
        sleep 5
    done
}


function doExtract {
    echo
    echo
    echo "EXTRACT"

    while read LINE
    do
        DATA=$(curl -sI "http://tinyurl.com/$LINE" | grep -Po "(?<=Location: )[\w=]*" )
        echo "DATA   : [$DATA]"

        echo -n "$DATA" >> "$B64"

        # workaround for quotas
        sleep 5
    done < "$ZIP"

    base64 -d "$B64" > "$BACKUP"
}


function showInfo {
    echo
    echo
    echo "DIFF"

    diff -s "$ORIG" "$BACKUP"
}


doPrepare
doCompress
doExtract
showInfo
