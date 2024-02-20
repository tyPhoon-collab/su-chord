// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$factoryContextHash() => r'4d72edce432d9c33b0127ccc9519f4d310606a7f';

///サンプルレートやSTFT時のwindowサイズやhop_lengthのサイズを保持する
///推定器に必要なデータを全て保持し、EstimatorFactoryに提供する
///Providerとして扱うことで、変更時にfactoryも更新できる
///
/// Copied from [factoryContext].
@ProviderFor(factoryContext)
final factoryContextProvider =
    AutoDisposeProvider<EstimatorFactoryContext>.internal(
  factoryContext,
  name: r'factoryContextProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$factoryContextHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FactoryContextRef = AutoDisposeProviderRef<EstimatorFactoryContext>;
String _$factoryHash() => r'0e66c108798a22d24719316087723eb8f77a8693';

/// See also [factory].
@ProviderFor(factory)
final factoryProvider = AutoDisposeProvider<EstimatorFactory>.internal(
  factory,
  name: r'factoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$factoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FactoryRef = AutoDisposeProviderRef<EstimatorFactory>;
String _$estimatorsHash() => r'dd58b0c5b6ba0c7465177f38a3b6a61ac7f3d22d';

///推定器の一覧
///フロントエンドでどの推定器を使うか選ぶことができる
///
/// Copied from [estimators].
@ProviderFor(estimators)
final estimatorsProvider =
    AutoDisposeProvider<Map<String, AsyncValueGetter<ChordEstimable>>>.internal(
  estimators,
  name: r'estimatorsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$estimatorsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EstimatorsRef
    = AutoDisposeProviderRef<Map<String, AsyncValueGetter<ChordEstimable>>>;
String _$estimatorHash() => r'205044e4790dc73798d8b93c2a46031cd6bed838';

/// See also [estimator].
@ProviderFor(estimator)
final estimatorProvider = AutoDisposeFutureProvider<ChordEstimable>.internal(
  estimator,
  name: r'estimatorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$estimatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EstimatorRef = AutoDisposeFutureProviderRef<ChordEstimable>;
String _$debugViewKeysHash() => r'fc720c43a2adacc6426ee41f65266e9d5d0f7d7a';

/// See also [debugViewKeys].
@ProviderFor(debugViewKeys)
final debugViewKeysProvider = Provider<Set<String>>.internal(
  debugViewKeys,
  name: r'debugViewKeysProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$debugViewKeysHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DebugViewKeysRef = ProviderRef<Set<String>>;
String _$detectableChordsHash() => r'5c373faa40af55b9881b09d9547978e3e32c60b0';

/// See also [DetectableChords].
@ProviderFor(DetectableChords)
final detectableChordsProvider =
    AutoDisposeNotifierProvider<DetectableChords, Set<Chord>>.internal(
  DetectableChords.new,
  name: r'detectableChordsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$detectableChordsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DetectableChords = AutoDisposeNotifier<Set<Chord>>;
String _$selectingEstimatorLabelHash() =>
    r'7c9ac57307575dce45d545efa6ddaa392d09cdef';

/// See also [SelectingEstimatorLabel].
@ProviderFor(SelectingEstimatorLabel)
final selectingEstimatorLabelProvider =
    AutoDisposeNotifierProvider<SelectingEstimatorLabel, String>.internal(
  SelectingEstimatorLabel.new,
  name: r'selectingEstimatorLabelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectingEstimatorLabelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectingEstimatorLabel = AutoDisposeNotifier<String>;
String _$isVisibleDebugHash() => r'61426de2a898ee7f761dab58f773d2b4a0d01e81';

/// See also [IsVisibleDebug].
@ProviderFor(IsVisibleDebug)
final isVisibleDebugProvider = NotifierProvider<IsVisibleDebug, bool>.internal(
  IsVisibleDebug.new,
  name: r'isVisibleDebugProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isVisibleDebugHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$IsVisibleDebug = Notifier<bool>;
String _$isSimplifyChordProgressionHash() =>
    r'f59f7d3740cc07b2c5d35563b8743d447b990c20';

/// See also [IsSimplifyChordProgression].
@ProviderFor(IsSimplifyChordProgression)
final isSimplifyChordProgressionProvider =
    NotifierProvider<IsSimplifyChordProgression, bool>.internal(
  IsSimplifyChordProgression.new,
  name: r'isSimplifyChordProgressionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isSimplifyChordProgressionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$IsSimplifyChordProgression = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
