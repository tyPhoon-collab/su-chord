import 'package:chord/utils/loaders/audio.dart';

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

  Future<AudioData> get nutcracker =>
      _loader.load('assets/evals/nutcracker.wav');

  Future<AudioData> get nutcrackerShort =>
      nutcracker.then((value) => value.cut(duration: 30));

  Future<AudioData> get G => sample.then((value) => value._cut(0));

  Future<AudioData> get C => sample.then((value) => value._cut(3));

  // ignore: non_constant_identifier_names
  Future<AudioData> get G_Em_Bm_C => sample.then((value) => value._cut(0, 4));
}

class CacheableAudioLoader {
  CacheableAudioLoader({required this.sampleRate}) : _cache = const {};

  final int sampleRate;
  final Map<String, AudioData> _cache;

  Future<AudioData> load(
    String path, {
    double? duration,
    double? offset,
  }) async {
    final key = '$path $duration $offset';
    if (_cache.containsKey(path)) return _cache[key]!;
    final data = await SimpleAudioLoader(path: path).load(
      sampleRate: sampleRate,
      duration: duration,
      offset: offset,
    );
    _cache[key] = data;
    return data;
  }
}

extension _CutEvaluationAudioByIndex on AudioData {
  AudioData _cut(int index, [int length = 1]) {
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
