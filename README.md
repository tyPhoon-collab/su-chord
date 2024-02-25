# chord

マイクなどの入力による、リアルタイムコード推定器の精度検証用アプリケーション

## はじめに

以下のChordEstimableを実装したクラスを検証できる

```dart
// domains/estimator.dart
abstract interface class ChordEstimable {
  ChordProgression estimate(AudioData data, {bool flush = true});

  ChordProgression flush();
}
```

- AudioDataは音声データの情報をラップしたクラス
  - サンプルレートと音声のバッファ配列を持つ
- ChordProgressionはChordCellの配列をラップしたクラス
- ChordCellは和音と時間を管理するクラス
- flushがtrueの時、音声のストリームが終了したことを表す
  - ffteaパッケージに依存しているため、この仕様になっている

実装したクラスを以下のMap型に登録することで、アプリケーションのドロップダウンから選択できるようになる

```dart
// service.dart
@riverpod
Map<String, AsyncValueGetter<ChordEstimable>> estimators(EstimatorsRef ref) {
  // snip...

  return {
    'main': () async =>
        PatternMatchingChordEstimator(
          chromaCalculable: factory.guitarRange.reassignment,
          filters: filters,
        ),
    // snip...
    'new your estimator': () async => YourChordEstimatorImpl(), // LIKE HERE
  };
}
```

また、テストコードを用意しているため、GUIなしでも検証できる

## プラットフォーム

### Web

FirebaseによってHosting中

<https://su-chord.web.app>

### iOS

ビルド可

### Android

ビルド可

## 設計方針

- Flutterでフロントエンドを実現する
- RiverPodを用いて状態管理
- インタフェースを切ることで実装の挿げ替えをする
  - 呼び出し可能クラスを多用している
    - ストラテジパターン
- 基本的にイミュータブルを意識して設計、実装しているが、一部はパフォーマンスを考えてミュータブルになっている
- ユニットテストで評価実験を行う

## セットアップ

### Flutter

- Flutter 3.19.0 以上
- Dart 3.3.0

### Python

- <https://zenn.dev/sion_pn/articles/d0f9e45716cabb>
- 仮想環境を用いているが、仮想環境関連のファイルはGitで管理していない
- 2023/11/27時点でパッケージなどの兼ね合いから3.11.6を使用している
