# chord

マイクなどの入力による、リアルタイムコード推定器の精度検証用アプリケーション

## はじめに

以下のChordEstimableを実装したクラスを検証できる

```dart
// domains/estimator.dart
abstract interface class ChordEstimable {
  ChordProgression estimate(AudioData data, [bool flush = true]);

  ChordProgression flush();
}
```

- AudioDataは音声データの情報をラップしたクラス
- ChordProgressionはChordの配列をラップしたクラス
- Chordは和音を管理するクラス
- flushがtureの時、音声のストリームが終了したことを表す

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

また、登録した推定器を用いて、ファイルの音声から推定結果を出したい場合は、以下のテストを実行すれば良い

```dart
// test/units/eval.dart
Future<void> main() async {
  // snip...
  final contexts = await _getEvaluatorContexts([
    'assets/evals/Halion_CleanGuitarVX',
    'assets/evals/Halion_CleanStratGuitar',
    'assets/evals/HojoGuitar',
    'assets/evals/RealStrat',
  ]);

  // snip...
  group('riverpods front end estimators', () {
    final container = ProviderContainer();
    final estimators = container.read(estimatorsProvider);

    // snip...
    test('one', () async {
      const id = 'new your estimator'; // CHANGE HERE or add new test

      final estimator = await estimators[id]!.call();
      _Evaluator(
        header: [id],
        estimator: estimator,
      ).evaluate(contexts, path: 'test/outputs/front_ends/$id.csv');
    });
  });
  // snip...
}
```

## プラットフォーム

現在はWebのみに対応

Flutterはクロスプラットフォームに対応できるため、マイク入力周りを整えれば、モバイルアプリにもビルドできる

### Web

FirebaseによってHosting中

#### Project Console

https://console.firebase.google.com/project/su-chord/overview

#### URL

https://su-chord.web.app

## 設計方針

- Flutterでフロントエンドを実現する
- RiverPodを用いてDIする
    - 状態管理も一部RiverPodに任せる
- ストラテジーパターンに近い
    - クラス名などは準拠していない
        - Contextに当たるものがChordEstimableになる
        - Contextというクラス名はStructやRecordなどに該当する、データの集合を管理するクラスに命名している
    - インタフェースでそれぞれの実装を付け替えられるようにしている
    - Strategyに当たるものは呼び出し可能クラスにしている
        - callメソッドの実装を強制するインタフェースが該当する
- 基本的にイミュータブルを意識して設計、実装しているが、一部はミュータブルになっている
- ユニットテストで評価実験を行う

## ライセンス

MIT

## 最終更新日

2023/09/10