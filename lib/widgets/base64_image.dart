import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Decodifica un data URI (`data:image/png;base64,...`) o una cadena base64
/// pura a bytes. Devuelve `null` si no es válido.
Uint8List? decodeBase64Image(String? source) {
  if (source == null || source.isEmpty) return null;
  try {
    final commaIndex = source.indexOf(',');
    final data = source.startsWith('data:') && commaIndex != -1
        ? source.substring(commaIndex + 1)
        : source;
    return base64Decode(data);
  } catch (_) {
    return null;
  }
}

/// Muestra una imagen almacenada como base64. Si falla, muestra [placeholder].
class Base64Image extends StatelessWidget {
  final String? source;
  final BoxFit fit;
  final Widget placeholder;
  final double? width;
  final double? height;

  const Base64Image({
    super.key,
    required this.source,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = decodeBase64Image(source);
    if (bytes == null) return placeholder;
    return Image.memory(
      bytes,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
