import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';

class PuzzlePreviewWidget extends StatefulWidget {
  final String imagePath;
  final int gridSize;

  const PuzzlePreviewWidget({
    super.key,
    required this.imagePath,
    this.gridSize = 3,
  });

  @override
  State<PuzzlePreviewWidget> createState() => _PuzzlePreviewWidgetState();
}

class _PuzzlePreviewWidgetState extends State<PuzzlePreviewWidget> {
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

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;

      setState(() {
        fullImage = uiImage;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
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
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: const Center(child: Text('Error loading image')),
      );
    }

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.gridSize,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: widget.gridSize == 3 ? 9 : 16, // 3x3 = 9, 4x4 = 16
        itemBuilder: (context, index) {
          final totalPieces = widget.gridSize == 3 ? 9 : 16;
          final lastPosition = totalPieces - 1;
          
          if (index == lastPosition) {
            // Empty space at the last position (bottom-right)
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[400]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.crop_square,
                  color: Colors.white54,
                  size: 16,
                ),
              ),
            );
          }

          // Map piece IDs based on grid size
          int pieceId;
          if (widget.gridSize == 3) {
            // 3x3: use selected pieces [0,1,2,4,5,6,8,9]
            final pieceIds = [0, 1, 2, 4, 5, 6, 8, 9];
            pieceId = pieceIds[index];
          } else {
            // 4x4: use all pieces 0-14
            pieceId = index;
          }

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
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
              borderRadius: BorderRadius.circular(4),
              child: CustomPaint(
                painter: PuzzlePiecePainter(
                  fullImage: fullImage!,
                  pieceId: pieceId,
                  gridSize: widget.gridSize == 3 ? 4 : 4, // Always 4x4 source grid
                ),
              ),
            ),
          );
        },
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
