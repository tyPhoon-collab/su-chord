import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/loaders/csv.dart';

import 'evals/evaluator.dart';

///サンプルレート22050でよく使用する音源をキャッシュしつつ取得するクラス
class DataSet {
  factory DataSet() => _instance ?? DataSet._();

  DataSet._();

  static DataSet? _instance;

  late final _loader = CacheableAudioLoader(sampleRate: 22050);

  late final osawa = OsawaDataSet(_loader);

  Future<AudioData> get sample => _loader.load(
        'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav',
        duration: 81,
      );

  Future<AudioData> get sampleSilent =>
      _loader.load('assets/evals/Halion_CleanGuitarVX_nonsilent/1_青春の影.wav');

  Future<AudioData> get nutcracker =>
      _loader.load('assets/evals/nutcracker.wav');

  Future<AudioData> get nutcrackerShort =>
      nutcracker.then((value) => value.cut(duration: 30));

  Future<AudioData> get G =>
      sample.then((value) => value.cutEvaluationAudioByIndex(0));

  Future<AudioData> get C =>
      sample.then((value) => value.cutEvaluationAudioByIndex(3));

  // ignore: non_constant_identifier_names
  Future<AudioData> get G_Em_Bm_C =>
      sample.then((value) => value.cutEvaluationAudioByIndex(0, 4));

  Future<AudioData> concat(String folderPath) async {
    return _loader.load(folderPath, buildCachingData: () async {
      final context = await EvaluationAudioDataContext.fromFolder(
        folderPath,
        const KonokiEADCDelegate(),
      );

      final data = context.fold(
        AudioData.empty(sampleRate: _loader.sampleRate),
        (value, element) => value.concat(element.data),
      );

      return data;
    });
  }
}

mixin class Cacheable<T> {
  final Map<String, T> _cache = {};
}

class CacheableAudioLoader with Cacheable<AudioData> {
  CacheableAudioLoader({required this.sampleRate});

  final int sampleRate;

  Future<AudioData> load(
    String path, {
    double? duration,
    double? offset,
    Future<AudioData> Function()? buildCachingData,
  }) async {
    final key = path;
    if (_cache.containsKey(path)) {
      return _cache[key]!.cut(
        duration: duration,
        offset: offset,
      );
    }
    final data = await buildCachingData?.call() ??
        await SimpleAudioLoader(path: path).load(sampleRate: sampleRate);
    _cache[key] = data;
    return data.cut(
      duration: duration,
      offset: offset,
    );
  }
}

class CacheableCSVLoader with Cacheable<List<List<dynamic>>> {
  CacheableCSVLoader();

  Future<List<List<dynamic>>> load(String path) async {
    final key = path;
    if (_cache.containsKey(path)) return _cache[key]!;
    final data = await SimpleCSVLoader(path: path).load();
    _cache[key] = data;
    return data;
  }
}

extension CutEvaluationAudioByIndex on AudioData {
  AudioData cutEvaluationAudioByIndex(int index, [int length = 1]) {
    assert(length > 0);
    return cut(duration: 4 * length + .1, offset: index * 4);
  }
}

class OsawaDataSet {
  OsawaDataSet(this._loader);

  final CacheableAudioLoader _loader;

  // ignore: non_constant_identifier_names
  Future<AudioData> get C3 => _loader.load('assets/evals/guitar_note_c3.wav');

  Future<AudioData> get C => _loader.load('assets/evals/guitar_normal_c.wav');
}
