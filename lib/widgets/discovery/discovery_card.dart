import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:flutter/cupertino.dart';

class DiscoveryCard extends StatefulWidget {
  final Map<String, dynamic> animal;
  final double swipeProgress;
  final String? swipeDirection;

  const DiscoveryCard({
    super.key,
    required this.animal,
    this.swipeProgress = 0.0,
    this.swipeDirection,
  });

  @override
  State<DiscoveryCard> createState() => _DiscoveryCardState();
}

class _DiscoveryCardState extends State<DiscoveryCard> {
  final PageController _carouselController = PageController();
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final photoUrls = List<String>.from(widget.animal['photoUrls'] ?? []);
    final name = widget.animal['name'] ?? 'Unknown';
    final age = widget.animal['age'] ?? '';
    final breed = widget.animal['breed'] ?? '';
    final species = widget.animal['species'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Single Image Carousel full height
            Positioned.fill(
              child: PageView.builder(
                controller: _carouselController,
                itemCount: photoUrls.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    photoUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            ),

            // Tinder-style "NOPE" Overlay
            if (widget.swipeDirection == 'left')
              Positioned(
                top: 50,
                left: 20,
                child: Builder(
                  builder: (context) {
                    final double opacityValue = (widget.swipeProgress.abs().clamp(0.0, 1.0) as num).toDouble();
                    return Opacity(
                      opacity: opacityValue,
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          'NOPE',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Quicksand',
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Tinder-style "LIKE" Overlay
            if (widget.swipeDirection == 'right')
              Positioned(
                top: 50,
                right: 20,
                child: Builder(
                  builder: (context) {
                    final double opacityValue = (widget.swipeProgress.abs().clamp(0.0, 1.0) as num).toDouble();
                    return Opacity(
                      opacity: opacityValue,
                      child: Transform.rotate(
                        angle: 0.5,
                        child: Text(
                          'LIKE',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Quicksand',
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Transparent gesture-blocker over bottom 35%
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).size.width * 0.35, // Approximate 35%
              child: AbsorbPointer(
                absorbing: true, // Prevent gestures
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Gradient Overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 200,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
            ),

            // Text and Icon
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '$name${age != '' ? ' · $age' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Quicksand',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).pushNamed(
                              AppRoutes.animalDetail,
                              arguments: {'animalId': widget.animal['id']},
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              CupertinoIcons.info_circle_fill,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (breed != '' || species != '')
                    Text(
                      '$breed${breed != '' && species != '' ? ' · ' : ''}$species',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                ],
              ),
            ),

            // Dot indicators
            if (photoUrls.length > 1)
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Row(
                  children: List.generate(photoUrls.length, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 3,
                        decoration: BoxDecoration(
                          color: index == _currentImageIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}