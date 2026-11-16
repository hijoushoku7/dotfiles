---
name: cd-setup
description: dc-setup 済みのサービスを main への push で自動デプロイする仕組み（GitHub Actions + Tailscale SSH）をプロジェクトに入れる。.github/workflows/deploy.yml と secrets 登録用の ./init.sh を作る。手動起動のみ — ユーザーが「/cd-setup」「cd-setup」と明示したときだけ使う。workflow を書いているだけでは使わない。
---

# cd-setup

ユーザーが名前で呼んだときだけ使う。設計と一度だけの手作業は `~/docs/cd.md` にある。

## やること

プロジェクトのルート（git レポ）で実行する:

```bash
~/.claude/skills/cd-setup/scripts/cd-setup.sh <server>
```

- `<server>` は本番サーバーの tailnet 上のホスト名。分からなければユーザーに聞く（推測しない）
- `<owner>/<repo>` は `gh repo view` から取る
- 作るもの:
  1. `.github/workflows/deploy.yml` — cd.md の「workflow の骨子」を埋めたもの
  2. `./init.sh` — `scripts/init.sh` のコピー。値は入っていないのでコミットしてよい
- 既にあるファイルは上書きしない。上書きが要るなら先にユーザーに確認する

## 生成後にユーザーへ伝えること

1. 2ファイルをコミットして push する（push した時点でデプロイが走るので、先に 2〜3 を済ませる）
2. 本番サーバーで `/srv/apps/<repo>` に clone する（`deploy` ユーザーの権限で）
3. 本番サーバーの `/srv/apps/<repo>` で、作業用ユーザーとして `./init.sh` を実行する
   - `production` Environment を作り（デプロイは main だけ）、`~/himitu/.env` から
     `TS_OAUTH_CLIENT_ID` / `TS_OAUTH_SECRET` だけを登録する

## ルール

- `pull_request_target` は使わない。トリガーは `push` to main だけ
- `tailscale/github-action` はタグではなく SHA で固定する
- `init.sh` は `.env` を `source` しない。secret の値は `--body` ではなく標準入力で渡す
