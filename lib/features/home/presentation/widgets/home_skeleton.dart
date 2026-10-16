import 'package:flutter/material.dart';

import '../../../../core/widgets/shimmer.dart';

/// Loading placeholder mirroring the home layout: category title + a row of
/// cards. One [Shimmer] wraps the whole group.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, _) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ShimmerBox(width: 120, height: 18, radius: 6),
            ),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _CardSkeleton(),
                    SizedBox(width: 12),
                    _CardSkeleton(),
                    SizedBox(width: 12),
                    _CardSkeleton(),
                    SizedBox(width: 12),
                    _CardSkeleton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ShimmerBox(width: double.infinity)),
          SizedBox(height: 4),
          ShimmerBox(width: 90, height: 14, radius: 4),
        ],
      ),
    );
  }
}
