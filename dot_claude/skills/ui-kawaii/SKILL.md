---
name: ui-kawaii
description: Rewamp UI (github.com/palakonweb/Rewamp-UI) のインタラクション設計を参照して、かわいい(kawaii)系のUIコンポーネントとモーションを作る。手動起動のみ — ユーザーが「/ui-kawaii」「ui-kawaii」と明示したときだけ使う。ボタン、トグル、ナビバー、カーソル、背景、カードなどに、物理ベースのばねアニメーションとパステル配色を組み合わせたかわいいUIが欲しいときに使う。
---

# ui-kawaii

Rewamp UI は "copy-paste, physically-accurate, Framer Motion駆動" のReactコンポーネント集で、magnetic navbar、jelly/morph系トグル、trail cursor、confetti button、glow orbなど、物理っぽい動きのインタラクションが揃っている。このスキルはその**モーションのロジック**(springの硬さ、追従の遅延、形状の変形の仕方)を参照し、見た目をkawaii方向(丸み・パステル・ぷにぷに感・ちょっとした擬人化)に寄せて作る。コードをそのまま移植するのではなく、動きの発想を借りて作り直す。

## 参照元の読み方

リポジトリ自体はNPMパッケージではなく、コンポーネントを直接プロジェクトにコピーする形式。該当コンポーネントは `src/components/ui/` 以下にある。実装を見たい時はGitHub API/rawで直接取得する:

```bash
gh api repos/palakonweb/Rewamp-UI/contents/src/components/ui | jq -r '.[].name'
gh api repos/palakonweb/Rewamp-UI/contents/src/components/ui/<ファイル名> -q .download_url | xargs curl -sL
```

参考になりやすいカテゴリと、kawaii化したときの読み替え方:

| 参照コンポーネントの系統 | 動きの特徴 | kawaii読み替え |
|---|---|---|
| `GlassOrbToggle` / `CosmicSparkleToggle` / `DayNightSkyToggle` | トグルがspringで弾んで切り替わり、背景が滑らかに変化 | 丸いキャラ(ほっぺ・目)が表情を変えながら弾む、パステルグラデ |
| `MagneticPillNavbar` / `FluidWaveNavbar` / `JellyScoopNavbar` | ホバーで吸い寄せられる/波打つ/ぷるんと凹む | ぷにぷにしたピルがマウスに寄ってきて揺れる、グミのような質感 |
| `PillTrailCursor` / `HalftoneDotCursor` / `GooglyEyesButton` | カーソル追従トレイル、目玉がマウスを追う | 星やハートのトレイル、キャラの目がカーソルを追う |
| `ConfettiButton` / `ShimmerButton` / `RainbowButton` / `SlideToConfirmButton` | クリックで紙吹雪/光沢が走る/スライドで確定 | クリックでハート・星が散る、虹色シマー、ぷにっと潰れるスライド確認 |
| `FluidMorphOrb` / `MarbledFluidOrb` / `ParticleMorphOrb` | 有機的にうねる/粒子が集まって形を作る | マシュマロ/わたあめのような揺らぎ、集まって顔文字になる粒子 |
| `DiagonalCardStack` / `FolderTabCard` / `PerspectiveFlipDeck` | カードが斜めに積まれる/3Dでめくれる | シールやカードゲームのような重なり、ぴょこっと弾むめくり |

これは網羅表ではない。必要なら上のコマンドで他のコンポーネントのソースも見てよい。

## 作り方の指針

1. **springベースの動き**を使う(CSS `ease`より物理的)。React環境ならFramer Motionの`spring`(`stiffness`高め・`damping`低めで弾む感じ)、プレーンCSS/JSなら `cubic-bezier` のオーバーシュートか、Web Animations APIで近似する。
2. **形は丸みを帯びさせる**: 角丸を大きめに、パーツを楕円・しずく型で構成する。
3. **配色はパステル + 高コントラストな差し色1つ**(例: ラベンダー/ミント/ピーチの地に、ビビッドなピンクや黄色のアクセント)。ダークモード前提にしない限り背景は明るめ。
4. **インタラクションに「反応」を足す**: ホバー/クリックで表情・弾み・光・パーティクルなど、ユーザー操作に対する小さなフィードバックを必ず入れる。参照元の「物理的に正確」という哲学を、「かわいく反応する」に翻訳する。
5. 過剰な演出で可読性やクリック領域を壊さない。かわいさは装飾ではなく動きのタイミング設計から生まれる — ホバー遅延、イージング、弾む量を調整して質感を作る。

## 出力先

- Reactプロジェクト内なら、対象コンポーネントとしてそのまま編集・追加する。
- 単体で見せたい/依頼がHTML成果物なら、Artifactツールで作る(`artifact-design`スキルを先に読み込むこと)。
- 既存のCSS設計(Tailwind等)があればそれに合わせる。新規に大きなアニメーションライブラリを追加しない — Framer Motionがすでに入っていればそれを使い、入っていなければCSS transition/keyframesで十分な場合が多い。
