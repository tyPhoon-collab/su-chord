import 'chroma.dart';

abstract interface class ScoreCalculable {
  double call(Chroma chroma, Chroma other);
}

final class CosineSimilarityScore implements ScoreCalculable {
  const CosineSimilarityScore();

  @override
  String toString() => 'cosine similarity';

  @override
  double call(Chroma chroma, Chroma other) => chroma.cosineSimilarity(other);
}

final class TonalCentroidScore implements ScoreCalculable {
  const TonalCentroidScore({
    this.r1 = 1,
    this.r2 = 1,
    this.r3 = .5,
  });

  final double r1;
  final double r2;
  final double r3;

  @override
  String toString() => 'tonal centroid';

  @override
  double call(Chroma chroma, Chroma other) =>
      TonalCentroid.fromPCP(PCP(chroma.toList()))
          .cosineSimilarity(TonalCentroid.fromPCP(PCP(other.toList())));
}
