#!/bin/bash

readonly ARTICLE_API_URL='https://qiita.com/api/v2/items'
readonly CACHE_FILE_PATH='./cache.json'

readonly ARTICLE_DIR=$1
readonly TOKEN=$2
readonly MAP_PATH=$3

# main
readonly changes=($(git diff --name-only HEAD^ HEAD | grep -e "$ARTICLE_DIR".*\.md))
map=$(cat $MAP_PATH)

for file in "${changes[@]}"; do
  posted_article=$(echo $map | grep $file)
  id=${posted_article##*,}

  title=$(cat "$file" | sed -n -e 's/<!--.*title="\([^\"]*\)".*-->$/\1/p')
  tag_list=($(cat "$file" | sed -n -e 's/<!--.*tag="\([^\"]*\)".*-->$/\1/p' | sed -e "s|,| |g"))
  private=$(cat "$file" | sed -n -e 's/<!--.*private="\([^\"]*\)".*-->$/\1/p')

  body=$(cat "$file" | grep -vE '^<!--.*-->$')

  jq -n --arg title "$title" --arg body "$body" --argjson private $private '{ title: $title, body: $body, private: $private}' |
    jq '.tags=[{name: ($ARGS.positional[])}]' --args "${tag_list[@]}" \
      >$CACHE_FILE_PATH

  if [ -z "$id" ]; then
    echo push
    id=$(curl -v $ARTICLE_API_URL \
      -H "Content-Type: application/json; charset=UTF-8" \
      -H 'X-Accept: application/json' \
      -H "Authorization: Bearer ${TOKEN}" \
      -d @$CACHE_FILE_PATH |
      jq -r .id)
    map="$map\n$file,${id}"
  else
    echo patch
    curl -X PATCH "$ARTICLE_API_URL/$id" \
      -H "Content-Type: application/json; charset=UTF-8" \
      -H 'X-Accept: application/json' \
      -H "Authorization: Bearer ${TOKEN}" \
      -d @$CACHE_FILE_PATH
  fi

  rm $CACHE_FILE_PATH
done

echo "$map" >$MAP_PATH
