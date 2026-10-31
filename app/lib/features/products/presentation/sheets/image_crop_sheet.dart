import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';

/// Interactive modal sheet to preview, crop, rotate, adjust, and change an image.
class ImageCropSheet extends StatefulWidget {
  const ImageCropSheet({
    super.key,
    required this.imageUrl,
    this.title,
    this.subtitle,
  });

  final String imageUrl;
  final String? title;
  final String? subtitle;

  static Future<String?> show(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? subtitle,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => ImageCropSheet(
        imageUrl: imageUrl,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<ImageCropSheet> createState() => _ImageCropSheetState();
}

class _ImageCropSheetState extends State<ImageCropSheet> {
  late String _currentImageUrl;
  String _selectedAspectRatio = '1:1';
  int _rotationQuarterTurns = 0;
  double _zoomLevel = 1.0;

  final List<String> _aspectRatios = const ['1:1', '4:3', '16:9'];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl;
  }

  Future<void> _handleChangeImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera, color: Color(0xFF0066FF)),
                title: const Text('Take New Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image, color: Color(0xFF10B981)),
                title: const Text('Choose Another from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null && mounted) {
        setState(() {
          _currentImageUrl = picked.path;
          _rotationQuarterTurns = 0;
          _zoomLevel = 1.0;
        });
      }
    }
  }

  double get _aspectRatioValue {
    switch (_selectedAspectRatio) {
      case '1:1':
        return 1.0;
      case '4:3':
        return 4 / 3;
      case '16:9':
        return 16 / 9;
      default:
        return 1.0;
    }
  }

  /// Bakes the preview (rotate + zoom + aperture crop) into a new PNG file.
  ///
  /// Previously "Save Image" returned the untouched original, so the crop /
  /// rotate / zoom controls were purely cosmetic.
  Future<String?> _renderEditedImage() async {
    if (_currentImageUrl.startsWith('http')) return _currentImageUrl;
    final file = File(_currentImageUrl);
    if (!file.existsSync()) return _currentImageUrl;

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    const outWidth = 900.0;
    final outHeight = outWidth / _aspectRatioValue;

    final quarterTurns = _rotationQuarterTurns % 4;
    final rotatedWidth = quarterTurns.isOdd ? image.height : image.width;
    final rotatedHeight = quarterTurns.isOdd ? image.width : image.height;
    final coverScale = math.max(outWidth / rotatedWidth, outHeight / rotatedHeight);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.translate(outWidth / 2, outHeight / 2);
    canvas.rotate(quarterTurns * math.pi / 2);
    canvas.scale(coverScale * _zoomLevel);
    canvas.drawImage(
      image,
      Offset(-image.width / 2, -image.height / 2),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final rendered = await picture.toImage(outWidth.round(), outHeight.round());
    final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    rendered.dispose();
    if (data == null) return _currentImageUrl;

    final outFile = File(
      '${Directory.systemTemp.path}/krm_product_'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await outFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return outFile.path;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    String? result;
    try {
      result = await _renderEditedImage();
    } catch (e) {
      debugPrint('Image crop failed: $e');
      result = _currentImageUrl;
    }
    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.inputBorder.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(14),

            // Header Row: Title + Change Button + Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title ?? 'Crop Image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.darkText,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        widget.subtitle ?? 'Position and crop your photo nicely',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.inputLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _handleChangeImage,
                  icon: const Icon(LucideIcons.camera, size: 14),
                  label: const Text('Change', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0066FF),
                    backgroundColor: const Color(0xFFEFF6FF),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const Gap(4),
                IconButton(
                  icon: Icon(LucideIcons.x, size: 20, color: colors.inputLabel),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 18,
                ),
              ],
            ),
            const Gap(14),

            // Aspect Ratio Selector Chips
            Row(
              children: [
                Text(
                  'Aspect Ratio: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.inputLabel,
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _aspectRatios.map((ratio) {
                        final isSelected = ratio == _selectedAspectRatio;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedAspectRatio = ratio),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? colors.primary : const Color(0xFFF1F3FB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ratio,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : colors.darkText,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(14),

            // Crop Box Viewport Area
            Container(
              width: double.infinity,
              height: 230,
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // The Image (Zoomable & Rotated)
                    RotatedBox(
                      quarterTurns: _rotationQuarterTurns,
                      child: Transform.scale(
                        scale: _zoomLevel,
                        child: _currentImageUrl.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: _currentImageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Center(
                                  child: Icon(LucideIcons.image, size: 40, color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(LucideIcons.image, size: 40, color: Colors.white.withValues(alpha: 0.5)),
                                ),
                              )
                            : Image.file(
                                File(_currentImageUrl),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(LucideIcons.image, size: 40, color: Colors.white.withValues(alpha: 0.5)),
                                ),
                              ),
                      ),
                    ),

                    // Semi-transparent Mask with Crop Aperture Window
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _aspectRatioValue,
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    spreadRadius: 200,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Rule of thirds grid lines
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(height: 0.8, color: Colors.white.withValues(alpha: 0.4)),
                                      Container(height: 0.8, color: Colors.white.withValues(alpha: 0.4)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(width: 0.8, color: Colors.white.withValues(alpha: 0.4)),
                                      Container(width: 0.8, color: Colors.white.withValues(alpha: 0.4)),
                                    ],
                                  ),
                                  // Corner markers
                                  const Align(
                                    alignment: Alignment.topLeft,
                                    child: _CropCorner(isTop: true, isLeft: true),
                                  ),
                                  const Align(
                                    alignment: Alignment.topRight,
                                    child: _CropCorner(isTop: true, isLeft: false),
                                  ),
                                  const Align(
                                    alignment: Alignment.bottomLeft,
                                    child: _CropCorner(isTop: false, isLeft: true),
                                  ),
                                  const Align(
                                    alignment: Alignment.bottomRight,
                                    child: _CropCorner(isTop: false, isLeft: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(12),

            // Controls Toolbar (Rotate, Zoom slider, Reset)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rotate Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3FB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.rotateCw, size: 15, color: colors.darkText),
                        const Gap(6),
                        Text(
                          'Rotate',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.darkText),
                        ),
                      ],
                    ),
                  ),
                ),

                // Zoom Level Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.zoomOut, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        if (_zoomLevel > 1.0) {
                          setState(() => _zoomLevel = (_zoomLevel - 0.2).clamp(1.0, 3.0));
                        }
                      },
                    ),
                    Text(
                      '${(_zoomLevel * 100).toInt()}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inputLabel),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.zoomIn, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        if (_zoomLevel < 3.0) {
                          setState(() => _zoomLevel = (_zoomLevel + 0.2).clamp(1.0, 3.0));
                        }
                      },
                    ),
                  ],
                ),

                // Reset Button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _rotationQuarterTurns = 0;
                      _zoomLevel = 1.0;
                      _selectedAspectRatio = '1:1';
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Reset',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inputLabel),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Action Buttons (Cancel + Apply & Crop)
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: AppOutlinedButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Gap(12),
                Expanded(
                  flex: 6,
                  child: AppPrimaryButton(
                    text: 'Save Image',
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CropCorner extends StatelessWidget {
  const _CropCorner({required this.isTop, required this.isLeft});

  final bool isTop;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(6) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(6) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(6) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(6) : Radius.zero,
        ),
      ),
    );
  }
}

