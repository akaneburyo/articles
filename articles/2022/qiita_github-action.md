<!-- title="GithubActionsからQiitaに自動投稿するスクリプトを作った" tag="Bash,ShellScript,GitHubActions" private="true" -->

## はじめに

技術記事達を Git で管理しておきたいと思い、どうせならば自動投稿を、、、と思って調べたところ ↓ の記事に出会いました。  
[【設定簡単】GitHub Actions を使ってリポジトリ上の技術記事を Qiita に自動で投稿しよう](https://zenn.dev/noraworld/articles/github-to-qiita-by-github-actions)

めっちゃ便利やん……と思いつつ、勉強をしたかったのもありシェルスクリプト縛りで作ってみました。

## できたもの

<details><summary>upload_articles.yml</summary><div>

```yml
name: Push to Qiita
on:
  push:
    branches:
      - main
env:
  ARTICLE_DIR: articles/
  MAP_FILE_PATH: article_map

jobs:
  post:
    runs-on: ubuntu-latest
    concurrency:
      group: ${{ github.workflow }}-${{ github.ref }}

    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 2

      - name: Upload to Qiita
        run: bash .github/workflows/upload_to_qiita.sh ${{ env.ARTICLE_DIR }} ${{ secrets.QIITA_ACCESS_TOKEN }} ${{ env.MAP_FILE_PATH }}

      - name: Diff
        id: diff
        run: |
          git add -N .
          git diff --name-only --exit-code
        continue-on-error: true

      - name: Update articles_map
        run: |
          git config user.name github-actions
          git config user.email github-actions@github.com
          git add .
          git commit -m "actions: updated map file"
          git push
        if: steps.diff.outcome == 'failure'\
```

</div></details>

`secrets.QIITA_ACCESS_TOKEN`に Qiita のアクセストークンが渡される想定です。
`main`への push きっかけでシェルスクリプトを実行し、map ファイルに更新があれば commit します。

後述するシェルスクリプトで Git のコミットログを使うのですが、`actions/checkout@v2`に対して`fetch-depth`を設定する必要があることに気づかず少しつまりました。

<details><summary>upload_to_qiita.sh</summary><div>

```sh
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
    id=$(curl -v $ARTICLE_API_URL \
      -H "Content-Type: application/json; charset=UTF-8" \
      -H 'X-Accept: application/json' \
      -H "Authorization: Bearer ${TOKEN}" \
      -d @$CACHE_FILE_PATH |
      jq -r .id)
    echo -e "$file,${id}\n" >>$MAP_PATH
  else
    curl -X PATCH "$ARTICLE_API_URL/$id" \
      -H "Content-Type: application/json; charset=UTF-8" \
      -H 'X-Accept: application/json' \
      -H "Authorization: Bearer ${TOKEN}" \
      -d @$CACHE_FILE_PATH
  fi

  rm $CACHE_FILE_PATH
done
```

</div></details>

一つ前の commit と差分をとり、`articles/`内にある`.md`のファイルに対して処理します。  
記事のタイトルやタグなどは

```html
<!-- title="GithubActionsからQiitaに投稿するスクリプトを作った" tag="Bash,ShellScript,GitHubActions" private="true" -->
```

↑ のような形で md ファイル内に記載し、取得します。

md ファイルと Qiita の記事を対応付けるために`article_map`にファイルパスと ID を記載しています。  
差分として検出されたファイルがここに記載されていた場合、`PATCH`で更新します。

## おわりに

この GithubAction は以下のリポジトリで動いています。(この記事も GithubAction から投稿されたものです)
https://github.com/akaneburyo/articles/tree/main/.github/workflows

なにかしらまだ良くないところが(沢山)ある気がします…  
気付き次第修正しながら使っていこうと思います。

---

ご意見/ご指摘/気になったこと/もっとこうすれば良くなる等、コメントいただけると大喜びします！
ありがとうございました！
