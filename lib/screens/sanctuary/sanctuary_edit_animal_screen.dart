import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../firebase_options.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class SanctuaryEditAnimalScreen extends StatefulWidget {
  final String? animalId;

  const SanctuaryEditAnimalScreen({Key? key, this.animalId}) : super(key: key);

  @override
  State<SanctuaryEditAnimalScreen> createState() => _SanctuaryEditAnimalScreenState();
}

class _SanctuaryEditAnimalScreenState extends State<SanctuaryEditAnimalScreen> {
  final List<String> _photoUrls = [];
  final List<File> _loadedAttachments = [];

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ageController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _healthStatusController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  bool _isSaving = false;

  String? _originalAnimalName;

  String? _selectedGender;
  String? _selectedAgeCategory;
  String? _selectedSize;
  String? _selectedAdoptionStatus;

  bool _showAttachmentOptionsCard = false;

  bool _showDeleteAnimalCard = false;
  String _deleteAnimalConfirmText = '';

  @override
  void initState() {
    super.initState();
    if (widget.animalId != null) {
      _loadAnimalData();
    }
  }

  Future<String?> _getMatchedAnimalKey() async {
    final snapshot = await _db.child('animals').get();

    if (snapshot.exists) {
      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in raw.entries) {
        final animal = Map<String, dynamic>.from(entry.value);
        if (animal['id'] == widget.animalId) {
          return entry.key;
        }
      }
    }

    return null;
  }

  Future<List<String>> _uploadNewAnimalImages() async {
    List<String> urls = [];

    for (var file in _loadedAttachments) {
      final fileName = '${_auth.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('animal_images').child(fileName);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      urls.add(downloadUrl);
    }

    return urls;
  }

  Future<void> _loadAnimalData() async {
    try {
      final animalSnap = await _db.child('animals').get();

      if (animalSnap.exists) {
        final raw = Map<String, dynamic>.from(animalSnap.value as Map);

        for (var entry in raw.entries) {
          final animal = Map<String, dynamic>.from(entry.value);
          if (animal['id'] == widget.animalId) {

            setState(() {
              _originalAnimalName = animal['name'];

              _nameController.text = animal['name'] ?? '';
              _descriptionController.text = animal['description'] ?? '';
              _ageController.text = (animal['age'] ?? '').toString();
              _speciesController.text = animal['species'] ?? '';
              _breedController.text = animal['breed'] ?? '';
              _healthStatusController.text = animal['healthStatus'] ?? '';
              _selectedGender = animal['gender'];
              _selectedAgeCategory = animal['ageCategory'];
              _selectedSize = animal['size'];
              _selectedAdoptionStatus = animal['adoptionStatus'];

              _photoUrls.clear();
              final rawUrls = animal['photoUrls'];
              if (rawUrls is List) {
                _photoUrls.addAll(rawUrls.whereType<String>());
              }
            });

            break;
          }
        }
      } else {
        debugPrint('No animals found in database.');
      }
    } catch (e) {
      debugPrint('Error loading animal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load animal data.')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showMessage('No logged-in user found.');
      setState(() => _isSaving = false);
      return;
    }

    final name = _nameController.text.trim();
    final age = _ageController.text.trim();
    final species = _speciesController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter the animal\'s name.');
      setState(() => _isSaving = false);
      return;
    }

    if (_selectedGender == null) {
      _showMessage('Please select a gender.');
      setState(() => _isSaving = false);
      return;
    }

    if (age.isEmpty || int.tryParse(age) == null) {
      _showMessage('Please enter a valid age.');
      setState(() => _isSaving = false);
      return;
    }

    if (_selectedAgeCategory == null) {
      _showMessage('Please select an age category.');
      setState(() => _isSaving = false);
      return;
    }

    if (species.isEmpty) {
      _showMessage('Please enter the species.');
      setState(() => _isSaving = false);
      return;
    }

    if (_selectedSize == null) {
      _showMessage('Please select a size.');
      setState(() => _isSaving = false);
      return;
    }

    if (_selectedAdoptionStatus == null) {
      _showMessage('Please select an adoption status.');
      setState(() => _isSaving = false);
      return;
    }

    final totalImages = _photoUrls.length + _loadedAttachments.length;
    if (totalImages < 1) {
      _showMessage('Please ensure at least one photo exists.');
      setState(() => _isSaving = false);
      return;
    }

    try {
      final matchedKey = await _getMatchedAnimalKey();
      if (matchedKey == null) {
        _showMessage('Animal not found. Cannot save changes.');
        return;
      }

      final newImageUrls = await _uploadNewAnimalImages();
      final finalImageUrls = [..._photoUrls, ...newImageUrls];

      final updatedAnimalData = {
        'id': widget.animalId,
        'name': name,
        'description': _descriptionController.text.trim(),
        'gender': _selectedGender,
        'age': int.parse(age),
        'ageCategory': _selectedAgeCategory,
        'species': species,
        'breed': _breedController.text.trim(),
        'size': _selectedSize,
        'healthStatus': _healthStatusController.text.trim(),
        'adoptionStatus': _selectedAdoptionStatus,
        'photoUrls': finalImageUrls,
        'uploadedBy': user.email,
      };

      await _db.child('animals').child(matchedKey).update(updatedAnimalData);

      _showMessage('Changes saved successfully!');
      if (mounted)
        Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Failed to update animal. Please try again.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteAnimal(String animalId) async {
    try {
      await FirebaseDatabase.instance.ref('animals/$animalId').remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animal deleted successfully.')),
      );

      if (mounted)
        Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting animal: $e')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _loadedAttachments.add(File(pickedFile.path));
        _showAttachmentOptionsCard = false;
      });
    }
  }

  Widget _buildAttachmentOptionsCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Attachment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                icon: const Icon(CupertinoIcons.photo),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await _pickImage(ImageSource.gallery);
                  setState(() => _showAttachmentOptionsCard = false);
                },
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                icon: const Icon(CupertinoIcons.camera),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await _pickImage(ImageSource.camera);
                  setState(() => _showAttachmentOptionsCard = false);
                },
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () =>
                    setState(() => _showAttachmentOptionsCard = false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAnimalCard(String animalName) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete Animal Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'To confirm deletion, type the animal\'s name preceded by @ (e.g., @Buddy). This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Quicksand'),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                labelText: 'Type @$animalName',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _deleteAnimalConfirmText = value;
                });
              },
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showDeleteAnimalCard = false;
                        _deleteAnimalConfirmText = '';
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),

                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _deleteAnimalConfirmText == '@$animalName'
                        ? () async {
                      await _deleteAnimal(widget.animalId!);
                    }
                        : null,
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                const Text(
                  'Edit Animal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Note: You can only upload up to 9 images for each animal.',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Quicksand'
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _loadedAttachments.length >= 9
                      ? null
                      : () {
                    setState(() {
                      _showAttachmentOptionsCard = true;
                    });
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(
                    _loadedAttachments.length >= 9
                        ? 'Max Images Reached'
                        : 'Add Images',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _loadedAttachments.length >= 9
                        ? Colors.grey.shade300
                        : Colors.white,
                    foregroundColor: _loadedAttachments.length >= 9
                        ? Colors.black45
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),

                if (_photoUrls.isNotEmpty || _loadedAttachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photoUrls.length + _loadedAttachments.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final isNetworkImage = index < _photoUrls.length;

                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isNetworkImage
                                  ? Image.network(
                                _photoUrls[index],
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              )
                                  : Image.file(
                                _loadedAttachments[index - _photoUrls.length],
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isNetworkImage) {
                                      _photoUrls.removeAt(index);
                                    } else {
                                      _loadedAttachments.removeAt(index - _photoUrls.length);
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                const Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Animal\'s name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write a brief description of the animal...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Gender',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: ['Male', 'Female', 'Unknown']
                      .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(
                      gender,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    hintText: 'Select Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Quicksand',
                    color: Colors.black,
                  ),
                  dropdownColor: Colors.white,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Age',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Animal\'s age in years (e.g., 2, 5)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Age Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _selectedAgeCategory,
                  items: ['Baby', 'Young', 'Adult', 'Senior']
                      .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAgeCategory = value!;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Select Age Category',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Quicksand',
                    color: Colors.black,
                  ),
                  dropdownColor: Colors.white,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Species',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _speciesController,
                  decoration: InputDecoration(
                    hintText: '(e.g., Dog, Cat, Rabbit)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Breed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _breedController,
                  decoration: InputDecoration(
                    hintText: 'Enter breed if known (e.g., Labrador)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Size',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _selectedSize,
                  items: ['Small', 'Medium', 'Large']
                      .map((size) => DropdownMenuItem(
                    value: size,
                    child: Text(
                      size,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSize = value!;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Select Size',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Quicksand',
                    color: Colors.black,
                  ),
                  dropdownColor: Colors.white,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Health Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _healthStatusController,
                  decoration: InputDecoration(
                    hintText: '(e.g., Vaccinated, Dewormed)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Adoption Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _selectedAdoptionStatus,
                  items: [
                    {'label': 'Available', 'value': 'available'},
                    {'label': 'Pending', 'value': 'pending'},
                    {'label': 'Adopted', 'value': 'adopted'},
                    {'label': 'Not Available', 'value': 'not_available'},
                  ].map((item) => DropdownMenuItem(
                    value: item['value'],
                    child: Text(
                      item['label']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAdoptionStatus = value!;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Select Adoption Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Quicksand',
                    color: Colors.black,
                  ),
                  dropdownColor: Colors.white,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () async {
                      setState(() {
                        _isSaving = true;
                      });
                      await _saveChanges();
                      setState(() {
                        _isSaving = false;
                      });
                    },
                    child: _isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                        : const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showDeleteAnimalCard = true;
                      });
                    },
                    child: const Text('Delete Animal'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_showAttachmentOptionsCard)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: _buildAttachmentOptionsCard(),
            ),
          if (_showDeleteAnimalCard && _originalAnimalName != null)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: _buildDeleteAnimalCard(_originalAnimalName!),
            ),
        ],
      ),
    );
  }
}