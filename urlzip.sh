 
#!/bin/bash

EXT=${1##*.}
echo $EXT
ZIP="${1%${EXT}}zip"
echo $ZIP
B64="${1%${EXT}}b64"
echo $B64
ORIG="${1%${EXT}}orig.${EXT}"
echo $ORIG


####################
## tidy up old run
for j in "${ZIP}" "${B64}" "${ORIG}"
do
    if [ -f "${j}" ]
    then
        echo "removing old ${j}"
        rm "${j}"
    fi
done


####################
## info
echo
echo "Original: "
cat ${1}


####################
## compress 
echo
echo "ENCODE"

for i in `base64 -w 1000 ${1}`;
do
    
    URL="http://www.google.com/${i}"
    echo "URL   : ${URL}"
    
    POST="{\"longUrl\": \"${URL}\"}"
    echo "POST  : ${POST}"
    
    JSON=$(curl -s https://www.googleapis.com/urlshortener/v1/url -H "Content-Type: application/json" -d "${POST}" | grep -Po '"id":.*?[^\\]",' )
    echo "JSON  : ${JSON}"
    
    SHORT=$(echo "${JSON}" | grep -Po '(?<=http://goo.gl/)[\w]+')
    echo "SHORT : ${SHORT}"
    
    echo ${SHORT} >> "${ZIP}"
    
done


####################
## extract
echo
echo "DECODE"

for i in `cat "${ZIP}"`
do
    JSON=$(curl -s "https://www.googleapis.com/urlshortener/v1/url?shortUrl=http://goo.gl/${i}"| grep -Po '"longUrl":.*?[^\\]",')
    echo "JSON  : ${JSON}"
    
    LONG=$(echo "${JSON}" | grep -Po '(?<=http://www.google.com/)[\w]+')
    echo "LONG  : ${LONG}"
    
    echo ${LONG} >> "${B64}"
done

base64 -d "${B64}" > "${ORIG}"


####################
## info
echo
echo "Extracted: "
cat "${ORIG}"
echo
diff "$1" "${ORIG}"


