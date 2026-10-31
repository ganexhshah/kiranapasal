import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import 'image_crop_sheet.dart';

class SampleGroceryPhoto {
  final String name;
  final String url;

  const SampleGroceryPhoto({required this.name, required this.url});
}

/// Lineless bottom sheet modal to choose an image from Camera, Gallery, or Presets, then crop it.
/// Supports cropping or removing an existing image when [currentImageUrl] is provided.
class ImageSourcePickerSheet extends StatelessWidget {
  const ImageSourcePickerSheet({
    super.key,
    this.currentImageUrl,
    this.title,
    this.showPresets = true,
  });

  final String? currentImageUrl;
  final String? title;
  final bool showPresets;

  static Future<String?> show(
    BuildContext context, {
    String? currentImageUrl,
    String? title,
    bool showPresets = true,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => ImageSourcePickerSheet(
        currentImageUrl: currentImageUrl,
        title: title,
        showPresets: showPresets,
      ),
    );
  }

  static const List<SampleGroceryPhoto> _samplePhotos = [
    SampleGroceryPhoto(
      name: 'Rice Bag',
      url: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
    ),
    SampleGroceryPhoto(
      name: 'Cooking Oil',
      url: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80',
    ),
    SampleGroceryPhoto(
      name: 'Noodles',
      url: 'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=400&q=80',
    ),
    SampleGroceryPhoto(
      name: 'Sugar',
      url: 'https://images.unsplash.com/photo-1622484212850-eb596d769edc?auto=format&fit=crop&w=400&q=80',
    ),
    SampleGroceryPhoto(
      name: 'Tea Pack',
      url: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=400&q=80',
    ),
    SampleGroceryPhoto(
      name: 'Salt',
      url: 'https://images.unsplash.com/photo-1518110925495-5fe2fda0442c?auto=format&fit=crop&w=400&q=80',
    ),
    SampleGroceryPhoto(
      name: 'Wheat Flour',
      url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
    ),
    SampleGroceryPhoto(
      name: 'Biscuits',
      url: 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  Future<void> _proceedToCrop(BuildContext context, String imageUrl) async {
    final cropped = await ImageCropSheet.show(
      context,
      imageUrl: imageUrl,
      title: title != null ? 'Crop $title' : 'Crop Image',
    );
    if (cropped != null && context.mounted) {
      Navigator.pop(context, cropped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasExisting = currentImageUrl != null && currentImageUrl!.trim().isNotEmpty;

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

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? (hasExisting ? 'Photo Options' : 'Add Image'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.darkText,
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, size: 20, color: colors.inputLabel),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 18,
                ),
              ],
            ),
            const Gap(14),

            // Source Options (Camera & Gallery)
            Row(
              children: [
                // Option 1: Camera
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final photo = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 85,
                          maxWidth: 1024,
                          maxHeight: 1024,
                        );
                        if (photo != null && context.mounted) {
                          await _proceedToCrop(context, photo.path);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Camera error: $e')),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.camera,
                                color: Color(0xFF0866FF),
                                size: 22,
                              ),
                            ),
                          ),
                          const Gap(10),
                          Text(
                            'Take Photo',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: colors.darkText,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'Open camera',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.inputLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(12),

                // Option 2: Gallery
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final photo = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                          maxWidth: 1024,
                          maxHeight: 1024,
                        );
                        if (photo != null && context.mounted) {
                          await _proceedToCrop(context, photo.path);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gallery error: $e')),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.image,
                                color: Color(0xFF10B981),
                                size: 22,
                              ),
                            ),
                          ),
                          const Gap(10),
                          Text(
                            'Choose Gallery',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: colors.darkText,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'From photos',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.inputLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (showPresets) ...[
              const Gap(18),
              // Option 3: Sample Grocery Photos
              Text(
                'Or Choose Preset Grocery Photo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.darkText,
                ),
              ),
              const Gap(10),

              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _samplePhotos.length,
                  separatorBuilder: (context, index) => const Gap(10),
                  itemBuilder: (context, index) {
                    final photo = _samplePhotos[index];
                    return InkWell(
                      onTap: () => _proceedToCrop(context, photo.url),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: photo.url,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 72,
                                height: 72,
                                color: const Color(0xFFF1F3FB),
                                child: const Icon(LucideIcons.package, size: 22, color: Color(0xFF94A3B8)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 72,
                                height: 72,
                                color: const Color(0xFFF1F3FB),
                                child: const Icon(LucideIcons.package, size: 22, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          const Gap(4),
                          SizedBox(
                            width: 72,
                            child: Text(
                              photo.name,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: colors.inputLabel,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            // Existing image options (Crop Current or Remove)
            if (hasExisting) ...[
              const Gap(14),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.crop, size: 18, color: Color(0xFF0066FF)),
                title: const Text('Crop Current Photo', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                onTap: () => _proceedToCrop(context, currentImageUrl!),
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFEF4444)),
                title: const Text(
                  'Remove Image',
                  style: TextStyle(fontSize: 13.5, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(context, ''), // empty string denotes removed
              ),
            ],
          ],
        ),
      ),
    );
  }
}
