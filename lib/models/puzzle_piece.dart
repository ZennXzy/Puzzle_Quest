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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'correctPosition': correctPosition,
      'currentPosition': currentPosition,
      'imagePath': imagePath,
      'isEmpty': isEmpty,
    };
  }

  factory PuzzlePiece.fromJson(Map<String, dynamic> json) {
    return PuzzlePiece(
      id: json['id'] as int,
      correctPosition: json['correctPosition'] as int,
      currentPosition: json['currentPosition'] as int,
      imagePath: json['imagePath'] as String,
      isEmpty: json['isEmpty'] as bool? ?? false,
    );
  }
}

class PuzzleState {
  final List<PuzzlePiece> pieces;

  const PuzzleState({
    required this.pieces,
  });

  Map<String, dynamic> toJson() {
    return {
      'pieces': pieces.map((piece) => piece.toJson()).toList(),
    };
  }

  factory PuzzleState.fromJson(Map<String, dynamic> json) {
    return PuzzleState(
      pieces: (json['pieces'] as List<dynamic>)
          .map((pieceJson) => PuzzlePiece.fromJson(pieceJson as Map<String, dynamic>))
          .toList(),
    );
  }
}
