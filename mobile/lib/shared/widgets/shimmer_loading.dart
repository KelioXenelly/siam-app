import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(child: ShimmerLoading(width: double.infinity, height: 90)),
              SizedBox(width: 12),
              Expanded(child: ShimmerLoading(width: double.infinity, height: 90)),
              SizedBox(width: 12),
              Expanded(child: ShimmerLoading(width: double.infinity, height: 90)),
            ],
          ),
          const SizedBox(height: 20),
          const ShimmerLoading(width: double.infinity, height: 180),
          const SizedBox(height: 20),
          const ShimmerLoading(width: double.infinity, height: 60),
        ],
      ),
    );
  }
}
