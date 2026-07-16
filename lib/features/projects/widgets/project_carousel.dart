import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';

class ProjectCarousel extends StatefulWidget {
  final String? coverImageUrl;
  final List<String>? galleryUrls;
  final bool isPublic;

  const ProjectCarousel({
    super.key,
    this.coverImageUrl,
    this.galleryUrls,
    this.isPublic = false,
  });

  @override
  State<ProjectCarousel> createState() => _ProjectCarouselState();
}

class _ProjectCarouselState extends State<ProjectCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Combine cover and gallery image URLs
    final List<String> images = [];
    if (widget.coverImageUrl != null && widget.coverImageUrl!.isNotEmpty) {
      images.add(widget.coverImageUrl!);
    }
    if (widget.galleryUrls != null && widget.galleryUrls!.isNotEmpty) {
      images.addAll(widget.galleryUrls!.where((url) => url.isNotEmpty));
    }

    // 1. Fallback: No images at all
    if (images.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            widget.isPublic ? Icons.volunteer_activism : Icons.folder_special,
            color: Colors.white.withAlpha(180),
            size: 48,
          ),
        ),
      );
    }

    // 2. Static view: Only 1 image
    if (images.length == 1) {
      return Image.network(
        images.first,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    }

    // 3. Carousel view: Multiple images
    return Stack(
      children: [
        // PageView
        Positioned.fill(
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
              );
            },
          ),
        ),

        // Counter Indicator (Top Right)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: AppRadius.radiusPill,
            ),
            child: Text(
              '${_currentPage + 1}/${images.length}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Dots Indicator (Bottom Center)
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: isActive ? 16 : 6,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white.withAlpha(120),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),

        // Left Navigation Arrow Button
        if (_currentPage > 0)
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.black.withAlpha(100),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          ),

        // Right Navigation Arrow Button
        if (_currentPage < images.length - 1)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.black.withAlpha(100),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: const Color(0xFFF7F6F2),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
      ),
    );
  }
}
