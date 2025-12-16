import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/auth_service.dart';
import '../utils/avatar_presets.dart';
import 'dart:typed_data';
import 'dart:convert';

class AvatarSelection extends StatefulWidget {
  final String? currentAvatarUrl;

  const AvatarSelection({super.key, this.currentAvatarUrl});

  @override
  State<AvatarSelection> createState() => _AvatarSelectionState();
}

class _AvatarSelectionState extends State<AvatarSelection> {
  int? _selectedPresetIndex;
  XFile? _selectedImageFile;
  Uint8List? _imageBytes;
  bool _isUploading = false;

  // final List<Map<String, dynamic>> _presetAvatars = [
  //   {'icon': Icons.person, 'color': Color(0xFF5F9F7A)},
  //   {'icon': Icons.face, 'color': Color(0xFF4A90E2)},
  //   {'icon': Icons.child_care, 'color': Color(0xFFE91E63)},
  //   {'icon': Icons.elderly, 'color': Color(0xFF9C27B0)},
  //   {'icon': Icons.boy, 'color': Color(0xFF2196F3)},
  //   {'icon': Icons.girl, 'color': Color(0xFFFF4081)},
  //   {'icon': Icons.man, 'color': Color(0xFF3F51B5)},
  //   {'icon': Icons.woman, 'color': Color(0xFFE91E63)},
  //   {'icon': Icons.accessibility_new, 'color': Color(0xFF00BCD4)},
  //   {'icon': Icons.sentiment_satisfied, 'color': Color(0xFFFFEB3B)},
  //   {'icon': Icons.favorite, 'color': Color(0xFFF44336)},
  //   {'icon': Icons.star, 'color': Color(0xFFFFC107)},
  // ];

  @override
  void initState() {
    super.initState();
    if (widget.currentAvatarUrl != null && widget.currentAvatarUrl!.startsWith('preset_')) {
      final index = int.tryParse(widget.currentAvatarUrl!.replaceFirst('preset_', ''));
      if (index != null && index < AvatarPresets.presets.length) {
        _selectedPresetIndex = index;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70, // Giảm chất lượng để giảm kích thước
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        
        // Kiểm tra kích thước (Firestore có giới hạn 1MB cho 1 field)
        if (bytes.length > 1 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ảnh quá lớn! Vui lòng chọn ảnh nhỏ hơn hoặc giảm chất lượng'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImageFile = image;
          _imageBytes = bytes;
          _selectedPresetIndex = null;
        });

        print('Image selected: ${bytes.length} bytes');
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _convertImageToBase64(Uint8List bytes) {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  Future<void> _saveAvatar() async {
    if (_selectedImageFile == null && _selectedPresetIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn avatar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String avatarUrl;

      if (_imageBytes != null) {
        print('Converting image to Base64...');
        // Chuyển ảnh thành Base64 string
        avatarUrl = _convertImageToBase64(_imageBytes!);
        print('Image converted, size: ${avatarUrl.length} characters');
      } else if (_selectedPresetIndex != null) {
        avatarUrl = 'preset_$_selectedPresetIndex';
        print('Using preset avatar: $avatarUrl');
      } else {
        throw Exception('Vui lòng chọn avatar');
      }

      // Cập nhật avatar trong Firestore
      print('Updating avatar in Firestore...');
      await AuthService.instance.updateUserAvatar(avatarUrl);
      print('Avatar updated successfully');

      if (mounted) {
        Navigator.pop(context, avatarUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật avatar thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: 50,
            right: -30,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/Them_Thuoc.png',
                width: 241.55,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F9F7A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Chọn Avatar',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5F3F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 50),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Preview avatar
                _buildPreview(),

                const SizedBox(height: 30),

                // Upload from gallery button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.upload),
                    label: const Text('Tải ảnh từ thư viện'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F9F7A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Hoặc chọn từ thư viện:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D5F3F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Preset avatars grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: AvatarPresets.presets.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedPresetIndex == index;

                      return GestureDetector(
                        onTap: _isUploading ? null : () {
                          setState(() {
                            _selectedPresetIndex = index;
                            _selectedImageFile = null;
                            _imageBytes = null;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2D5F3F) : Colors.transparent,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AvatarPresets.presets[index]['image'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF5F9F7A),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Save button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _saveAvatar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5F3F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isUploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Đang lưu...',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Lưu',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildPreviewContent(),
    );
  }

  Widget _buildPreviewContent() {
    if (_imageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _imageBytes!,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_selectedPresetIndex != null) {
      return AvatarPresets.buildAvatar(
        index: _selectedPresetIndex!,
        size: 150,
      );
    }

    // Hiển thị avatar hiện tại
    if (widget.currentAvatarUrl != null) {
      // Nếu là preset
      if (widget.currentAvatarUrl!.startsWith('preset_')) {
        final index = int.tryParse(widget.currentAvatarUrl!.replaceFirst('preset_', ''));
        if (index != null && index < AvatarPresets.presets.length) {
          return AvatarPresets.buildAvatar(
            index: index,
            size: 150,
          );
        }
      }
      
      // Nếu là Base64
      if (widget.currentAvatarUrl!.startsWith('data:image')) {
        try {
          final base64String = widget.currentAvatarUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          );
        } catch (e) {
          print('Error decoding base64 avatar: $e');
        }
      }
      
      // Nếu là URL
      if (widget.currentAvatarUrl!.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            widget.currentAvatarUrl!,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF5F9F7A),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF5F9F7A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 80, color: Colors.white),
              );
            },
          ),
        );
      }
    }

    // Default avatar
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF5F9F7A),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.white,
      ),
    );
  }
}