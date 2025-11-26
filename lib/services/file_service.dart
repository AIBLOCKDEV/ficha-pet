import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class FileService {
  Future<String> imageToBase64(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final extension = path.extension(imagePath);
      final ext = extension.isNotEmpty && extension.length > 1 
          ? extension.substring(1) 
          : 'png';
      return 'data:image/$ext;base64,$base64String';
    } catch (e) {
      throw Exception('Error converting image to base64: $e');
    }
  }

  Future<String> fileToBase64(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final extension = path.extension(filePath);
      final ext = extension.isNotEmpty && extension.length > 1 
          ? extension.substring(1) 
          : 'pdf';
      return 'data:application/$ext;base64,$base64String';
    } catch (e) {
      throw Exception('Error converting file to base64: $e');
    }
  }
}

