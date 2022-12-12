<!-- title="TipTap を react-hook-form と使う" tag="React,tiptap,react-hook-form" private="false" -->

## 目的

- 少しリッチな入力ができるようにしたい
- 既存の入力欄と組み合わせて、react-hook-form で管理したい

## できたもの

https://codesandbox.io/embed/musing-diffie-x5yqp2?fontsize=14&hidenavigation=1&theme=dark

tiptap 側は[markdown-shortcuts](https://tiptap.dev/examples/markdown-shortcuts)のサンプルと、管理画面的なところで使うことを想定して[placeholder](https://tiptap.dev/api/extensions/placeholder)を組み合わせました。

コンポーネントの分割と名前は[React Hook Form を 1 年以上運用してきたちょっと良く使うための Tips in ログラス（と現状の課題）](https://zenn.dev/yuitosato/articles/292f13816993ef)を参考にさせていただきました。

## 詰まった所

### 一文字入力する度に入力欄からフォーカスが外れる

`useEditor`(src/components/Editor/Editor.tsx#L44)で tiptap の Editor を初期化する際、`onUpdate`で`onChange`(外から渡される onChange = react-hook-form の state を更新する onChange)を呼ぶようにした所、一文字入力する度に入力欄からフォーカスが外れるようになってしまいました。

##### 原因

(当たり前かもしれませんが)onUpdate で react-hook-form の state を更新すると`onBlur`/`onChange`等のメソッドが再生成されるため、

1. これらのメソッドに依存している`useEditor`が再実行される
1. `editor`のインスタンスが新しいものになる
1. editor 部分が再描画される
1. フォーカスが外れる

のような動きになっていたのではないかと思っています。

苦し紛れの対応として、`onBlur`時に onChange 的な意味合いのメソッド(src/components/Editor/Editor.tsx#L60)を呼ぶようにして対応しました。

## prosemirror-commands, prosemirror-keymap 等の import エラー

この記事の内容とは少し異なりますが、tiptap の最近のバージョンで不具合(?)があるようです。
https://github.com/ueberdosis/tiptap/issues/3492

いくつかのパッケージを追加してあげることで、一旦起動できるようになりました。
私の環境では以下が必要でした。

```bash
yarn add \
  prosemirror-schema-list \
  prosemirror-keymap \
  prosemirror-gapcursor \
  prosemirror-history \
  prosemirror-dropcursor \
  prosemirror-commands
```

---

ご意見/ご指摘/気になったこと/もっとこうすれば良くなる等、コメントいただけると大喜びします！
ありがとうございました！
