import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../services/ml_prediction_service.dart';

class CropDetailsScreen extends StatefulWidget {
  final String cropName;

  const CropDetailsScreen({
    super.key,
    required this.cropName,
  });

  @override
  State<CropDetailsScreen> createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends State<CropDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Future<Map<String, dynamic>> _cropDetailsFuture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cropDetailsFuture =
        Future.value(MLPredictionService.getCropDetailsInfo(widget.cropName));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${widget.cropName} Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050A14),
              Color(0xFF0B1221),
              Color(0xFF050A14),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _cropDetailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading details',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              final details = snapshot.data ?? {};

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 375),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        // Crop Header
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF4CAF50).withOpacity(0.2),
                                const Color(0xFF45A049).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cropName,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Scientific: ${details['scientificName'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF4CAF50)
                                        .withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  'Season: ${details['season'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description
                        Text(
                          'Overview',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white10,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.05),
                          ),
                          child: Text(
                            details['description'] ??
                                'Crop information not available.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Growing Parameters
                        Text(
                          'Growing Parameters',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        _buildParameterCard(
                          icon: Icons.schedule,
                          title: 'Harvest Days',
                          value: details['harvestDays'] ?? 'N/A',
                          color: const Color(0xFF42A5F5),
                        ),
                        const SizedBox(height: 12),
                        _buildParameterCard(
                          icon: Icons.thermostat,
                          title: 'Temperature',
                          value: details['temperature'] ?? 'N/A',
                          color: const Color(0xFFFF6B6B),
                        ),
                        const SizedBox(height: 12),
                        _buildParameterCard(
                          icon: Icons.cloud_queue,
                          title: 'Rainfall',
                          value: details['rainfall'] ?? 'N/A',
                          color: const Color(0xFF26C6DA),
                        ),
                        const SizedBox(height: 12),
                        _buildParameterCard(
                          icon: Icons.science,
                          title: 'pH Range',
                          value: details['ph'] ?? 'N/A',
                          color: const Color(0xFF7C4DFF),
                        ),
                        const SizedBox(height: 12),
                        _buildParameterCard(
                          icon: Icons.grain,
                          title: 'NPK Requirements',
                          value: details['npk'] ?? 'N/A',
                          color: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 24),

                        // Benefits
                        if ((details['benefits'] as List?)?.isNotEmpty ?? false)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Advantages',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              ...(details['benefits'] as List<dynamic>)
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _buildBenefitItem(
                                        entry.value.toString(),
                                        const Color(0xFF4CAF50),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              const SizedBox(height: 12),
                            ],
                          ),

                        // Challenges
                        if ((details['challenges'] as List?)?.isNotEmpty ??
                            false)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Challenges',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              ...(details['challenges'] as List<dynamic>)
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _buildBenefitItem(
                                        entry.value.toString(),
                                        const Color(0xFFFF6B6B),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildParameterCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
