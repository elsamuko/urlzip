#!/usr/bin/env bash

# check for GNU base64 with wrap option
base64 --help 2>&1 | grep GNU > /dev/null || { echo "Error: Could not find GNU grep"; exit 1; }

if [ ! -f "$1" ]
then
    echo "Usage: $(basename "$0") <file>"
    exit 1
fi

EXT=${1##*.}
echo "$EXT"
ZIP="${1%$EXT}zip"
echo "$ZIP"
B64="${1%$EXT}b64"
echo "$B64"
ORIG="${1%$EXT}orig.$EXT"
echo "$ORIG"


####################
## tidy up old run
for j in "$ZIP" "$B64" "$ORIG"
do
    if [ -f "$j" ]
    then
        echo "removing old $j"
        rm "$j"
    fi
done


####################
## info
echo
echo "Original: "
# cat "$1"


####################
## compress 
echo
echo
echo "ENCODE"

for i in $(base64 -w 1000 "$1");
do

    URL="http://www.google.com/$i"
    echo "URL   : $URL"

    POST="{\"longUrl\": \"$URL\"}"
    echo "POST  : $POST"

    JSON=$(curl -s "https://www.googleapis.com/urlshortener/v1/url" -H "Content-Type: application/json" -d "$POST" | grep -Po '"id":.*?[^\\]",' )
    echo "JSON  : $JSON"

    SHORT=$(echo "$JSON" | grep -Po '(?<=http://goo.gl/)[^\"]+')
    echo "SHORT : $SHORT"

    echo "$SHORT" >> "$ZIP"
    echo

    # google quota
    sleep 120
done


####################
## extract
echo
echo
echo "DECODE"

while read LINE
do
    JSON=$(curl -s "https://www.googleapis.com/urlshortener/v1/url?shortUrl=http://goo.gl/$LINE"| grep -Po '"longUrl":.*?[^\\]",')
    echo "JSON  : $JSON"

    LONG=$(echo "$JSON" | grep -Po '(?<=http://www.google.com/)[^\"]+')
    echo "LONG  : $LONG"

    echo "$LONG" >> "$B64"
    echo

    # google quota
    sleep 120
done < "$ZIP"

base64 -d "$B64" > "$ORIG"


####################
## info
echo
echo
echo "Extracted: "
# cat "$ORIG"
echo
diff -s "$1" "$ORIG"


