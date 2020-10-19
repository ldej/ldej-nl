#!/bin/bash

FILES="./static/to_process/*"

for file in $FILES
do
    filename=$(basename -- "$file")
    filename="${filename%.*}"
    convert "$file" -resize 1440x "$file"
    cwebp "$file" -o "./static/images/$filename.webp"
done