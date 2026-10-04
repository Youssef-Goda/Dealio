import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// A thin, platform-aware wrapper around [ImageCropper].
///
/// On **web** the cropper is not supported — the original [XFile] is returned
/// unchanged so callers do not need to check [kIsWeb] themselves.
///
/// On **mobile / desktop** the native cropper is shown with the supplied
/// [aspectRatio].  Returns `null` if the user cancels.
class ImageCropHelper {
  ImageCropHelper._(); 

  static const Color _toolbarColor = Color(0xFF121212);
  static const Color _accentColor = Color(0xFFFFD700);

  /// Crops [source] to [aspectRatio].
  ///
  /// Pass `null` for [aspectRatio] to allow the user to pick any ratio freely.
  ///
  /// Returns the cropped [XFile] on success, `null` on cancel, and [source]
  /// unchanged when running on web.
  static Future<XFile?> crop(
    XFile source, {
    CropAspectRatio? aspectRatio,
  }) async {
    // Web: ImageCropper is not available — pass through unchanged.
    if (kIsWeb) return source;

    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: source.path,
      aspectRatio: aspectRatio,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: _toolbarColor,
          toolbarWidgetColor: _accentColor,
          backgroundColor: _toolbarColor,
          activeControlsWidgetColor: _accentColor,
          initAspectRatio: aspectRatio != null
              ? CropAspectRatioPreset.ratio16x9
              : CropAspectRatioPreset.original,
          lockAspectRatio: aspectRatio != null,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: aspectRatio != null,
        ),
      ],
    );

    if (cropped == null) return null;
    return XFile(cropped.path);
  }

  /// Convenience shortcut: **16:9** crop for banner images.
  static Future<XFile?> cropBanner(XFile source) =>
      crop(source, aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9));

  /// Convenience shortcut: **1:1** crop for avatars (displayed as circle).
  static Future<XFile?> cropAvatar(XFile source) =>
      crop(source, aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1));

  /// Convenience shortcut: free-form crop for product images.
  static Future<XFile?> cropProduct(XFile source) =>
      crop(source, aspectRatio: null);
}
