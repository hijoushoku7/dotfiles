# CD: GitHub Actions + Tailscale SSH

dc-setup で traefik のラベルを付けたサービスを、main への push で自動デプロイする。

## 構成

```
push to main
  → GitHub-hosted runner
  → tailscale/github-action で tailnet に参加（ephemeral, tag:ci）
  → Tailscale SSH で deploy@server
  → cd /srv/apps/<repo> && git pull && docker compose up -d --build
```

## workflow の骨子

```yaml
on:
  push:
    branches: [main]

concurrency: deploy-${{ github.repository }}

jobs:
  deploy:
    if: github.repository == '<owner>/<repo>'   # fork ではスキップ
    runs-on: ubuntu-latest
    environment: production                     # secrets はここに置く
    steps:
      - uses: tailscale/github-action@<sha>     # SHA で固定
        with:
          oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
          oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
          tags: tag:ci
      - run: ssh deploy@<server> "cd /srv/apps/${{ github.event.repository.name }} && git pull && docker compose up -d --build"
```

## 手動でやること

一度だけ:

- 本番サーバーに Tailscale を入れ、`tag:prod` 付き・Tailscale SSH 有効で tailnet に参加させる（下記「本番サーバーの Tailscale」）
- Tailscale ACL に `tag:ci` を定義し、`tag:ci → tag:prod:22` だけを許可する
- Tailscale SSH のルールで、`tag:ci` が入れるユーザーを `deploy` だけにする
- OAuth client（scope: auth keys の書き込み、tag: `tag:ci`）を作る
- サーバーに `deploy` ユーザーを作り、docker グループに入れる
- デプロイ元のディレクトリ `/srv/apps` を作る（下記「デプロイ元のディレクトリ」）
- 全レポの contents を読み取れる fine-grained PAT を1つ作り、`deploy` の git credential に登録する
- 作業用ユーザーで `~/himitu/.env` を作り、`gh auth login` する（下記「~/himitu/.env とユーザーの権限」）

レポを追加するたび:

- `production` Environment を作り、デプロイできるブランチを main に限定する
- `TS_OAUTH_CLIENT_ID` / `TS_OAUTH_SECRET` を登録する（`./init.sh` で行う）
- サーバーの `/srv/apps/<repo>` に clone する

## /cd-setup スキル

レポを追加するたびの手作業をなくすため、新しいスキル `cd-setup` を作る。dc-setup と同じく、ユーザーが `/cd-setup` と明示したときだけ使う。

このスキルは、対象のプロジェクトに次の2つを作る。

1. **自動デプロイ用の workflow**（`.github/workflows/deploy.yml`）
   - 上の「workflow の骨子」をもとに、`<owner>/<repo>` と `<server>` を埋めて生成する
2. **secrets 登録用のスクリプト**（`./init.sh`）
   - 本番サーバー上の `~/himitu/.env` を読み込み、その中身を GitHub secrets に登録する。読み込む場所はどのプロジェクトでも共通
   - `production` Environment の作成と secrets の登録をまとめて行う
   - `.env` から **`TS_OAUTH_CLIENT_ID` と `TS_OAUTH_SECRET` だけ**を取り出して登録する。ほかの変数が書いてあっても登録しない
   - `.env` は `source` せず、`grep` で該当する行だけを読む（`.env` の中身をシェルとして実行しない）
   - どちらかが見つからない、または値が空なら、何も登録せずにエラーで止まる
   - Environment の作成は `gh api` で行う。登録は1つずつ `gh secret set <NAME> --env production` で行い、値は標準入力から渡す（`--body` で渡すと `ps` からコマンドライン経由で見えてしまう）
   - スクリプトに値は書かないので、`init.sh` はコミットしてよい
   - dc-setup と同じように、スキル側に置いたものをプロジェクトにコピーして使う

## 本番サーバーの Tailscale

今は Tailscale を LXC にだけ入れていて、本番には ProxyJump で入っている。Tailscale SSH が使えるのは tailscaled が動いているノードだけなので、本番にも Tailscale を入れて tailnet に直接参加させる。

```sh
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --advertise-tags=tag:prod
```

- `--ssh` で Tailscale SSH を有効にする。本番の sshd の設定と鍵は CI では使わない
- タグを付けたノードは、デフォルトで鍵の有効期限が切れない。期限切れでデプロイが突然止まることがない
- 本番に直接届くようになるので、CI は LXC を経由しない。自分が手作業で入るときの ProxyJump は今のまま残してよい

ACL（既存のルールに追加する）:

```jsonc
{
  "tagOwners": {
    "tag:ci":   ["autogroup:admin"],
    "tag:prod": ["autogroup:admin"]
  },
  "grants": [
    { "src": ["tag:ci"], "dst": ["tag:prod"], "ip": ["tcp:22"] }
  ],
  "ssh": [
    { "action": "accept", "src": ["tag:ci"], "dst": ["tag:prod"], "users": ["deploy"] }
  ]
}
```

## デプロイ元のディレクトリ

デプロイ元は作業用ユーザーのホームではなく、`/srv/apps/<repo>` に置く。

- ホームを `700` にすると `deploy` が中に入れず、`git pull` できない
- 逆に `deploy` が書き込めるようにホームの権限を開けると、`~/himitu` まで危なくなる
- `/srv` は FHS で「サーバーが提供するサービスのデータを置く場所」と決められている。OS もパッケージも使わないので衝突しない

### 作成

```sh
sudo mkdir -p /srv/apps
sudo chown deploy:deploy /srv/apps
sudo chmod 2775 /srv/apps                  # setgid: 中に作ったファイルも deploy グループになる
sudo usermod -aG deploy <作業用ユーザー>   # 作業用ユーザーも手作業で編集できるようにする
```

- グループの追加は、作業用ユーザーがログインし直してから反映される
- 作業用ユーザーで `/srv/apps/<repo>` の git を触ると、所有者が違うため `dubious ownership` で拒否される。`git config --global --add safe.directory '/srv/apps/*'` で許可する

### ホームから移すとき

```sh
cd ~/<repo> && docker compose down
sudo mv ~/<repo> /srv/apps/
sudo chown -R deploy:deploy /srv/apps/<repo>   # コンテナが root で書いたファイルも揃える
cd /srv/apps/<repo> && docker compose up -d
```

- ディレクトリ名を変えなければ compose のプロジェクト名も変わらないので、named volume はそのまま引き継がれる
- `./data` のような相対パスの bind mount は、ディレクトリごと移せばデータも一緒に移る

## ~/himitu/.env とユーザーの権限

`init.sh` は本番サーバー上で、**作業用ユーザー（自分が普段ログインするユーザー）**で実行する。`~/himitu` は作業用ユーザーのホームに置き、`deploy` ユーザーのホームには置かない。

`deploy` には CI から Tailscale SSH で入れる。もし `deploy` から `.env` や `gh` のトークンが読めると、CI 経由で Tailscale の secret と GitHub の書き込み権限が取られてしまう。

### ファイルの権限

```sh
mkdir -p ~/himitu && chmod 700 ~/himitu
install -m 600 /dev/null ~/himitu/.env   # 中身を書く前に 600 で作っておく
chmod 700 ~                              # ホームを他のユーザーから読めないようにする
```

- 所有者は作業用ユーザーにして、グループと他のユーザーには一切読ませない
- git の管理下には置かない

### ユーザーの権限

| ユーザー | 用途 | 権限 |
|---|---|---|
| 作業用ユーザー | `init.sh` の実行、`~/himitu/.env` の所有 | deploy グループに所属（`/srv/apps` を編集できる）。`gh auth login` 済み。トークンには対象レポの Secrets と Environments を書き込める権限（Administration: write）が必要。sudo は可 |
| `deploy` | CI から入って `git pull` と `docker compose up` を行う | docker グループのみ。`/srv/apps` の所有者。sudo なし、パスワードでのログインなし。`~/himitu` は読めない。git credential は contents の読み取り専用 PAT |

## この方式にした理由

- **常駐プロセスが要らない。** 個人アカウントでは self-hosted runner をレポごとに登録する必要があり、レポ数ぶんプロセス（待機中 約100MB/個）とサービスが増えていく。
- **SSH 鍵を管理しなくてよい。** Tailscale SSH を使うので、認証は ACL だけで済む。
- **受信ポートを開けなくてよい。** cloudflared 構成のまま、Tailscale 経由で到達できる。
- **コストがほぼかからない。** 1回のデプロイは1分弱。public レポは無料で、private レポも月2000分の無料枠に収まる。
- **public レポでも安全。** job は GitHub 側の使い捨て VM で動くので、悪意あるコードが実行されても自分のサーバーには影響しない（self-hosted runner だとサーバー上で実行されてしまう）。

## セキュリティ

- fork からの PR には secrets が渡されない。fork 先のレポにも secrets はコピーされない。
- デプロイは `push` to main だけで発火するので、main に入るのは自分が merge したときだけ。
- `pull_request_target` は使わない（secrets 付きで PR のコードが動いてしまう）。
- 外部コントリビューターの PR で Actions を動かすには承認が必要、という設定にしておく（Settings → Actions → General）。
- secret が漏れたときの被害範囲は、`tag:ci` に許可した 22番ポート と `deploy` ユーザーまで。ただし `deploy` は docker グループに入っているので、実質 root まで届く。ACL は広げないこと。

## 採用しなかった案

| 案 | 採用しなかった理由 |
|---|---|
| self-hosted runner | 個人アカウントではレポごとに登録が必要。public レポではサーバー上で他人のコードが動く危険がある |
| SSH 鍵を secret に置く | 鍵と known_hosts の管理が増える |
| 今の LXC を踏み台にする | 本番用の SSH 鍵を LXC に置き、forced command を設定する必要がある。本番に Tailscale を入れるほうが手順が少ない |
| pull 型（systemd timer） | 反映が遅れる。ログが Actions の画面に出ず、失敗しても通知が来ない |
