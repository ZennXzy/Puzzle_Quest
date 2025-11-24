import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
import '../models/puzzle_piece.dart';

class PuzzleWidget extends StatefulWidget {
  final String imagePath;
  final int gridSize;
  final Function(bool) onPuzzleComplete;

  const PuzzleWidget({
    super.key,
    required this.imagePath,
    this.gridSize = 3,
    required this.onPuzzleComplete,
  });

  @override
  State<PuzzleWidget> createState() => _PuzzleWidgetState();
}

class _PuzzleWidgetState extends State<PuzzleWidget> {
  List<PuzzlePiece> pieces = [];
  ui.Image? fullImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final imageData = await DefaultAssetBundle.of(context).load(widget.imagePath);
      final bytes = imageData.buffer.asUint8List();

      // Decode image using Flutter's built-in decoder
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;

      setState(() {
        fullImage = uiImage;
        _initializePuzzle();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _initializePuzzle() {
    if (fullImage == null) return;

    pieces.clear();

    // Create 3x3 puzzle pieces from a 4x4 dimension photo
    // We'll use pieces from positions: 0,1,2,4,5,6,8,9,10 (skipping 3,7,11,12,13,14,15)
    final selectedPieceIds = [0, 1, 2, 4, 5, 6, 8, 9, 10];

    // Create pieces in correct order first
    for (int i = 0; i < selectedPieceIds.length; i++) {
      final pieceId = selectedPieceIds[i];
      pieces.add(PuzzlePiece(
        id: pieceId,
        correctPosition: i,
        currentPosition: i,
        imagePath: widget.imagePath,
      ));
    }

    // Add empty piece at the last position (position 8) - this is the 3x3 slot that gets removed
    pieces.add(PuzzlePiece(
      id: -1,
      correctPosition: 8,
      currentPosition: 8,
      imagePath: '',
      isEmpty: true,
    ));

    // Shuffle the pieces to create a more challenging solvable puzzle
    // Perform random valid moves for better randomization
    final random = Random();
    for (int shuffleCount = 0; shuffleCount < 500; shuffleCount++) {
      // Perform random valid moves
      final emptyIndex = pieces.indexWhere((piece) => piece.isEmpty);
      final possibleMoves = _getPossibleMoves(emptyIndex);

      if (possibleMoves.isNotEmpty) {
        final randomMove = possibleMoves[random.nextInt(possibleMoves.length)];
        _performMove(randomMove);
      }
    }

    // Reassign current positions after shuffling
    for (int i = 0; i < pieces.length; i++) {
      pieces[i] = pieces[i].copyWith(currentPosition: i);
    }
  }

  List<int> _getPossibleMoves(int emptyIndex) {
    final possibleMoves = <int>[];
    final emptyRow = emptyIndex ~/ 3;
    final emptyCol = emptyIndex % 3;

    // Check all four directions
    final directions = [
      [-1, 0], // up
      [1, 0],  // down
      [0, -1], // left
      [0, 1],  // right
    ];

    for (final direction in directions) {
      final newRow = emptyRow + direction[0];
      final newCol = emptyCol + direction[1];

      if (newRow >= 0 && newRow < 3 && newCol >= 0 && newCol < 3) {
        final newIndex = newRow * 3 + newCol;
        possibleMoves.add(newIndex);
      }
    }

    return possibleMoves;
  }

  void _performMove(int pieceIndex) {
    final emptyIndex = pieces.indexWhere((piece) => piece.isEmpty);
    final tappedPiece = pieces[pieceIndex];

    // Swap positions
    pieces[emptyIndex] = tappedPiece.copyWith(currentPosition: emptyIndex);
    pieces[pieceIndex] = PuzzlePiece(
      id: -1,
      correctPosition: 8,
      currentPosition: pieceIndex,
      imagePath: '',
      isEmpty: true,
    );
  }

  void _onPieceTap(int index) {
    final emptyIndex = pieces.indexWhere((piece) => piece.isEmpty);
    final tappedPiece = pieces[index];

    // Check if the tapped piece can move (adjacent to empty space)
    if (_canMove(index, emptyIndex)) {
      setState(() {
        // Swap positions
        pieces[emptyIndex] = tappedPiece.copyWith(currentPosition: emptyIndex);
        pieces[index] = PuzzlePiece(
          id: -1,
          correctPosition: 8,
          currentPosition: index,
          imagePath: '',
          isEmpty: true,
        );

        // Check if puzzle is complete
        if (_isPuzzleComplete()) {
          widget.onPuzzleComplete(true);
        }
      });
    }
  }

  bool _canMove(int pieceIndex, int emptyIndex) {
    final pieceRow = pieceIndex ~/ 3;
    final pieceCol = pieceIndex % 3;
    final emptyRow = emptyIndex ~/ 3;
    final emptyCol = emptyIndex % 3;

    // Check if adjacent (up, down, left, right)
    return (pieceRow == emptyRow && (pieceCol - emptyCol).abs() == 1) ||
           (pieceCol == emptyCol && (pieceRow - emptyRow).abs() == 1);
  }

  bool _isPuzzleComplete() {
    for (final piece in pieces) {
      if (!piece.isEmpty && piece.currentPosition != piece.correctPosition) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (fullImage == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: const Center(child: Text('Error loading image')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.gridSize,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: pieces.length,
            itemBuilder: (context, index) {
              final piece = pieces[index];

              if (piece.isEmpty) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[400]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.crop_square,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => _onPieceTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(
                      painter: PuzzlePiecePainter(
                        fullImage: fullImage!,
                        pieceId: piece.id,
                        gridSize: 4, // Original 4x4 grid
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class PuzzlePiecePainter extends CustomPainter {
  final ui.Image fullImage;
  final int pieceId;
  final int gridSize;

  PuzzlePiecePainter({
    required this.fullImage,
    required this.pieceId,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pieceWidth = fullImage.width / gridSize;
    final pieceHeight = fullImage.height / gridSize;

    final row = pieceId ~/ gridSize;
    final col = pieceId % gridSize;

    final srcRect = Rect.fromLTWH(
      col * pieceWidth,
      row * pieceHeight,
      pieceWidth,
      pieceHeight,
    );

    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(fullImage, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
