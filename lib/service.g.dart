// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$factoryContextHash() => r'22a39bbcb2a9548876859c419c983f2742f38cf4';

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
String _$estimatorsHash() => r'2fbe574387af4317ffa98dab3b0b6d7856f708ab';

///推定器の一覧
///フロントエンドでどの推定器を使うか選ぶことができる
///
/// Copied from [estimators].
@ProviderFor(estimators)
final estimatorsProvider = AutoDisposeProvider<
    Map<String, Future<ChordEstimable> Function()>>.internal(
  estimators,
  name: r'estimatorsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$estimatorsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EstimatorsRef
    = AutoDisposeProviderRef<Map<String, Future<ChordEstimable> Function()>>;
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
String _$detectableChordsHash() => r'98d8eae622c673a1680863d29dc4670cf3ee7345';

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
String _$isVisibleDebugHash() => r'26698fcb57e9c4ad065783e8477404eaee88a583';

/// See also [IsVisibleDebug].
@ProviderFor(IsVisibleDebug)
final isVisibleDebugProvider =
    AutoDisposeNotifierProvider<IsVisibleDebug, bool>.internal(
  IsVisibleDebug.new,
  name: r'isVisibleDebugProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isVisibleDebugHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$IsVisibleDebug = AutoDisposeNotifier<bool>;
String _$selectingEstimatorLabelHash() =>
    r'111796f7a1c6128575aff2231cab2d4ae501a888';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member
