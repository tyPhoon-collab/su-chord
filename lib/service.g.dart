// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$factoryContextHash() => r'bddc873a0816601c74179444e6e7b6459209c1e8';

/// See also [factoryContext].
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
String _$estimatorsHash() => r'd28cbb8b10aaf91fcb218a437955ef24c931f2a8';

/// See also [estimators].
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
String _$selectingEstimatorLabelHash() =>
    r'ee53aea4e0c83c2dc5b8447ea470c5137273981b';

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
