import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_options.dart';
import '../theme/theme.dart';
import '../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:pawpal_application/widgets/discovery/discovery_card.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/discovery_filter.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  DiscoveryFilter _currentFilter = DiscoveryFilter();
  List<Map<String, dynamic>> _animalList = [];
  int _currentIndex = 0;

  final CardSwiperController _swiperController = CardSwiperController();
  bool _canUndo = false;

  @override
  void initState() {
    super.initState();
    _fetchFilteredAnimals();
  }

  Future<void> _fetchFilteredAnimals() async {
    final ref = FirebaseDatabase.instance.ref('animals');
    final snapshot = await ref.orderByChild('adoptionStatus').equalTo('available').once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      List<Map<String, dynamic>> filteredList = data.values
          .map((e) => Map<String, dynamic>.from(e))
          .where((animal) {
        final gender = animal['gender'];
        final size = animal['size'];
        final ageCategory = animal['ageCategory'];
        final speciesRaw = animal['species'];

        String speciesForFilter;
        if (speciesRaw == 'Dog' || speciesRaw == 'Cat') {
          speciesForFilter = speciesRaw;
        } else {
          speciesForFilter = 'Other';
        }

        if (_currentFilter.genderList.isNotEmpty &&
            !_currentFilter.genderList.contains(gender)) {
          return false;
        }

        if (_currentFilter.sizeList.isNotEmpty &&
            !_currentFilter.sizeList.contains(size)) {
          return false;
        }

        if (_currentFilter.ageList.isNotEmpty &&
            !_currentFilter.ageList.contains(ageCategory)) {
          return false;
        }

        if (_currentFilter.speciesList.isNotEmpty &&
            !_currentFilter.speciesList.contains(speciesForFilter)) {
          return false;
        }

        return true;
      }).toList();

      setState(() {
        _animalList = filteredList;
        _currentIndex = 0;
      });
    } else {
      setState(() {
        _animalList = [];
        _currentIndex = 0;
      });
    }
  }

  void _goToNextAnimal() {
    if (_currentIndex < _animalList.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _rewindAnimal() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _recordSwipe(String animalId, String direction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    String node = (direction.toLowerCase() == 'like') ? 'likes' : 'dislikes';

    final ref = FirebaseDatabase.instance.ref('swipes/$animalId/$node/${user.email!.replaceAll('.', ',')}');

    await ref.set({
      'animalId': animalId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _handleUndo() {
    if (_canUndo && _currentIndex > 0) {
      final lastAnimalId = _animalList[_currentIndex - 1]['id'];
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.email != null) {
        final path = 'swipes/$lastAnimalId/likes/${user.email!.replaceAll('.', ',')}';
        final dislikePath = 'swipes/$lastAnimalId/dislikes/${user.email!.replaceAll('.', ',')}';

        FirebaseDatabase.instance.ref(path).remove();
        FirebaseDatabase.instance.ref(dislikePath).remove();
      }

      _swiperController.undo();
      setState(() {
        _canUndo = false;
      });
    }
  }

  BorderRadius? _buildOptionRadius(int index, int total) {
    if (index == 0) {
      return const BorderRadius.horizontal(left: Radius.circular(30));
    } else if (index == total - 1) {
      return const BorderRadius.horizontal(right: Radius.circular(30));
    }
    return null;
  }

  Widget _buildFilterSection({
    required String label,
    required List<String> options,
    required List<String> selectedOptions,
    required Function(List<String>) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand',
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: List.generate(options.length * 2 - 1, (i) {
                if (i.isOdd) {
                  return Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.withOpacity(0.2),
                  );
                }

                final index = i ~/ 2;
                final option = options[index];
                final bool isSelected = selectedOptions.contains(option);

                return Expanded(
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    borderRadius: _buildOptionRadius(index, options.length),
                    onTap: () {
                      final updatedList = List<String>.from(selectedOptions);
                      if (isSelected) {
                        updatedList.remove(option);
                      } else {
                        updatedList.add(option);
                      }
                      onSelect(updatedList);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4DED88).withOpacity(0.2) : Colors.transparent,
                        borderRadius: _buildOptionRadius(index, options.length),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            option,
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF4DED88) : Colors.black,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle, color: Color(0xFF4DED88), size: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        DiscoveryFilter tempFilter = DiscoveryFilter.from(_currentFilter);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                      'Filters',
                      style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.bold
                      )
                  ),

                  const SizedBox(height: 16),

                  _buildFilterSection(
                    label: 'Gender',
                    options: ['Male', 'Female'],
                    selectedOptions: tempFilter.genderList,
                    onSelect: (val) => setModalState(() => tempFilter.genderList = val),
                  ),

                  _buildFilterSection(
                    label: 'Size',
                    options: ['Small', 'Medium', 'Large'],
                    selectedOptions: tempFilter.sizeList,
                    onSelect: (val) => setModalState(() => tempFilter.sizeList = val),
                  ),

                  _buildFilterSection(
                    label: 'Age',
                    options: ['Baby', 'Young', 'Adult', 'Senior'],
                    selectedOptions: tempFilter.ageList,
                    onSelect: (val) => setModalState(() => tempFilter.ageList = val),
                  ),

                  _buildFilterSection(
                    label: 'Species',
                    options: ['Dog', 'Cat', 'Other'],
                    selectedOptions: tempFilter.speciesList,
                    onSelect: (val) => setModalState(() => tempFilter.speciesList = val),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
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
                              setModalState(() {
                                tempFilter = DiscoveryFilter();
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 8),

                        SizedBox(
                          width: 100,
                          child: ElevatedButton(
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
                            onPressed: () {
                              Navigator.pop(context, tempFilter);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    )
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result is DiscoveryFilter) {
        setState(() {
          _currentFilter = result;
          _fetchFilteredAnimals();
        });
      }
    });
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black26,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 32),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              iconSize: 30,
              icon: const Icon(CupertinoIcons.slider_horizontal_3, color: Colors.black),
              onPressed: _showFilterSheet,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _animalList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : CardSwiper(
              controller: _swiperController,
              cardsCount: _animalList.length,
              allowedSwipeDirection: AllowedSwipeDirection.only(left: true, right: true),
              cardBuilder: (context, index, percentX, percentY) {
                if (index < _animalList.length) {
                  String? direction;
                  if (percentX < -0.05) direction = 'left';
                  if (percentX > 0.05) direction = 'right';

                  return DiscoveryCard(
                    animal: _animalList[index],
                    swipeProgress: percentX.clamp(-1.0, 1.0).toDouble(),
                    swipeDirection: direction,
                  );
                }
                return null;
              },
              onSwipe: (previousIndex, currentIndex, direction) {
                setState(() {
                  _currentIndex = currentIndex ?? 0;
                  _canUndo = true;
                });

                if (previousIndex != null && previousIndex < _animalList.length) {
                  final animalId = _animalList[previousIndex]['id'];

                  if (direction == CardSwiperDirection.left) {
                    _recordSwipe(animalId, 'Dislike');
                  } else if (direction == CardSwiperDirection.right) {
                    _recordSwipe(animalId, 'Like');
                  }
                }

                return true;
              },
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.close, const Color(0xFFFF3C3C), () {
                _swiperController.swipe(CardSwiperDirection.left);
              }),
              const SizedBox(width: 24),

              _buildActionButton(Icons.refresh, Color(0xFFFFC800), _handleUndo),
              const SizedBox(width: 24),

              _buildActionButton(CupertinoIcons.heart_fill, const Color(0xFF4DED88), () {
                _swiperController.swipe(CardSwiperDirection.right);
              }),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}