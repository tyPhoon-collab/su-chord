# chord

マイクなどの入力による、リアルタイムコード推定器の精度検証用アプリケーション

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
    'new your estimator': () async => YourChordEstimatorImpl(),
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
      const id = 'new your estimator'; // ここを新しく作った推定器の名前に変更する

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

FirebaseによってHosting

個人のアカウントなので、他の人がリリース版を更新したい場合は、適宜別のプロジェクトでデプロイしてください

#### Project Console

https://console.firebase.google.com/project/su-chord/overview

#### URL

https://su-chord.web.app
