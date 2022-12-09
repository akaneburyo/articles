<!-- title="GithubActionsからQiitaに自動投稿するスクリプトを作った" tag="Bash,ShellScript,GitHubActions" private=""true" private="true" -->

## はじめに

技術記事達を Git で管理しておきたいと思い、どうせならば自動投稿を、、、と思って調べたところ ↓ の記事に出会いました。  
[【設定簡単】GitHub Actions を使ってリポジトリ上の技術記事を Qiita に自動で投稿しよう](https://zenn.dev/noraworld/articles/github-to-qiita-by-github-actions)

めっちゃ便利やん……と思いつつ、勉強をしたかったのもありシェルスクリプト縛りで作ってみました。

## できたもの

ここにおいてあります。  
https://github.com/akaneburyo/articles/tree/main/.github/workflows

## 苦戦ポイント

- 改行コードの扱い
- sed(なにもわからん)
- jq(なにもわからん)

---

ご意見/ご指摘/気になったこと/もっとこうすれば良くなる等、コメントいただけると大喜びします！
ありがとうございました！
