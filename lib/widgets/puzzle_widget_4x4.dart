import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import '../models/puzzle_piece.dart';

class PuzzleWidget4x4 extends StatefulWidget {
  final String imagePath;
  final Function(bool) onPuzzleComplete;

  const PuzzleWidget4x4({
    super.key,
    required this.imagePath,
    required this.onPuzzleComplete,
  });

  @override
  State<PuzzleWidget4x4> createState() => _PuzzleWidget4x4State();
}

class _PuzzleWidget4x4State extends State<PuzzleWidget4x4> {
  List<PuzzlePiece> pieces = [];
  ui.Image? fullImage;
  bool isLoading = true;
  late AudioPlayer _audioPlayer;
  final List<String> _slideSounds = [
    'audio/slideAudio#1.mp3',
    'audio/slideAudio#2.mp3',
    'audio/slideAudio#3.mp3',
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadImage();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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

    // Create 15 playable pieces (IDs 0-14)
    for (int i = 0; i < 15; i++) {
      pieces.add(PuzzlePiece(
        id: i,
        correctPosition: i,
        currentPosition: i,
        imagePath: widget.imagePath,
      ));
    }

    // Add empty piece at position 15 (bottom-right) - stays fixed
    pieces.add(PuzzlePiece(
      id: 15,
      correctPosition: 15,
      currentPosition: 15,
      imagePath: '',
      isEmpty: true,
    ));

    // Shuffle only the playable pieces (not the empty slot)
    // Keep empty slot fixed at bottom-right (position 15)
    final random = Random();
    final playablePieces = pieces.sublist(0, pieces.length - 1);
    
    // Fisher-Yates shuffle for playable pieces only
    for (int i = playablePieces.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = playablePieces[i];
      playablePieces[i] = playablePieces[j];
      playablePieces[j] = temp;
    }

    // Reassign current positions with empty slot fixed at the end
    for (int i = 0; i < playablePieces.length; i++) {
      pieces[i] = playablePieces[i].copyWith(currentPosition: i);
    }
    // Empty slot stays at last position
    pieces[pieces.length - 1] = pieces[pieces.length - 1].copyWith(currentPosition: pieces.length - 1);
  }

  List<int> _getPossibleMoves(int emptyIndex) {
    final possibleMoves = <int>[];
    final emptyRow = emptyIndex ~/ 4;
    final emptyCol = emptyIndex % 4;

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

      if (newRow >= 0 && newRow < 4 && newCol >= 0 && newCol < 4) {
        final newIndex = newRow * 4 + newCol;
        possibleMoves.add(newIndex);
      }
    }

    return possibleMoves;
  }

  void _performMove(int pieceIndex) {
    final emptyIndex = pieces.indexWhere((piece) => piece.isEmpty);
    final tappedPiece = pieces[pieceIndex];

    // Swap positions: move the tapped piece to empty slot, empty slot takes tapped piece's position
    pieces[emptyIndex] = tappedPiece.copyWith(currentPosition: emptyIndex);
    pieces[pieceIndex] = PuzzlePiece(
      id: 15,
      correctPosition: 15,
      currentPosition: pieceIndex,
      imagePath: '',
      isEmpty: true,
    );
  }

  void _onPieceSwipe(int index, DragEndDetails details) {
    final emptyIndex = pieces.indexWhere((piece) => piece.isEmpty);

    // Check if the swipe direction is towards the empty space AND the piece is adjacent to the empty slot
    if (_isSwipeTowardsEmpty(index, emptyIndex, details) && _isAdjacentToEmpty(index, emptyIndex)) {
      // Play slide sound effect
      _playSlideSound();

      setState(() {
        // Perform the move
        _performMove(index);

        // Check if puzzle is complete
        if (_isPuzzleComplete()) {
          widget.onPuzzleComplete(true);
        }
      });
    }
  }

  bool _isSwipeTowardsEmpty(int pieceIndex, int emptyIndex, DragEndDetails details) {
    final pieceRow = pieceIndex ~/ 4;
    final pieceCol = pieceIndex % 4;
    final emptyRow = emptyIndex ~/ 4;
    final emptyCol = emptyIndex % 4;

    // Determine swipe direction based on velocity
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;

    // Horizontal swipe
    if (dx.abs() > dy.abs()) {
      if (dx > 0 && emptyCol > pieceCol && emptyRow == pieceRow) {
        // Swipe right towards empty space
        return true;
      } else if (dx < 0 && emptyCol < pieceCol && emptyRow == pieceRow) {
        // Swipe left towards empty space
        return true;
      }
    }
    // Vertical swipe
    else {
      if (dy > 0 && emptyRow > pieceRow && emptyCol == pieceCol) {
        // Swipe down towards empty space
        return true;
      } else if (dy < 0 && emptyRow < pieceRow && emptyCol == pieceCol) {
        // Swipe up towards empty space
        return true;
      }
    }

    return false;
  }

  bool _isAdjacentToEmpty(int pieceIndex, int emptyIndex) {
    final pieceRow = pieceIndex ~/ 4;
    final pieceCol = pieceIndex % 4;
    final emptyRow = emptyIndex ~/ 4;
    final emptyCol = emptyIndex % 4;

    // Check if the piece is directly adjacent to the empty slot (up, down, left, right)
    final rowDiff = (pieceRow - emptyRow).abs();
    final colDiff = (pieceCol - emptyCol).abs();

    // Adjacent if exactly one row or one column difference, but not both
    return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
  }

  void _playSlideSound() {
    final random = Random();
    final randomSound = _slideSounds[random.nextInt(_slideSounds.length)];
    _audioPlayer.play(AssetSource(randomSound));
  }

  void _testPuzzleComplete() {
    // Set up puzzle with all pieces in their correct positions
    // This makes the puzzle immediately complete
    pieces.clear();
    
    // Create all 15 playable pieces (0-14) in their correct positions
    for (int i = 0; i < 15; i++) {
      pieces.add(PuzzlePiece(
        id: i,
        correctPosition: i,
        currentPosition: i,
        imagePath: widget.imagePath,
      ));
    }
    
    // Add empty piece at position 15 (correct position)
    pieces.add(PuzzlePiece(
      id: 15,
      correctPosition: 15,
      currentPosition: 15,
      imagePath: '',
      isEmpty: true,
    ));
    
    // Trigger puzzle complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPuzzleComplete(true);
    });
  }

  bool _isPuzzleComplete() {
    for (final piece in pieces) {
      if (piece.currentPosition != piece.correctPosition) {
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
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    // Check if this is the empty slot position
                    if (index >= pieces.length || (index < pieces.length && pieces[index].isEmpty)) {
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
                            size: 20,
                          ),
                        ),
                      );
                    }

                    final piece = pieces[index];

                    return GestureDetector(
                      onPanEnd: (details) => _onPieceSwipe(index, details),
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
                            painter: PuzzlePiecePainter4x4(
                              fullImage: fullImage!,
                              pieceId: piece.id,
                              gridSize: 4,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Test button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  _testPuzzleComplete();
                });
              },
              child: const Text(
                'TEST: Almost Complete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PuzzlePiecePainter4x4 extends CustomPainter {
  final ui.Image fullImage;
  final int pieceId;
  final int gridSize;

  PuzzlePiecePainter4x4({
    required this.fullImage,
    required this.pieceId,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Don't render image for empty slot or invalid pieces
    if (pieceId < 0 || pieceId >= gridSize * gridSize) return;

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
