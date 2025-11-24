class PuzzlePiece {
  final int id;
  final int correctPosition;
  final int currentPosition;
  final String imagePath;
  final bool isEmpty;

  const PuzzlePiece({
    required this.id,
    required this.correctPosition,
    required this.currentPosition,
    required this.imagePath,
    this.isEmpty = false,
  });

  PuzzlePiece copyWith({
    int? id,
    int? correctPosition,
    int? currentPosition,
    String? imagePath,
    bool? isEmpty,
  }) {
    return PuzzlePiece(
      id: id ?? this.id,
      correctPosition: correctPosition ?? this.correctPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      imagePath: imagePath ?? this.imagePath,
      isEmpty: isEmpty ?? this.isEmpty,
    );
  }
}
