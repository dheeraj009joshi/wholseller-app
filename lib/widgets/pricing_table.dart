import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';

class PricingTable extends StatelessWidget {
  final Map<String, double> pricingTiers;

  const PricingTable({
    super.key,
    required this.pricingTiers,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bulk Pricing',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...pricingTiers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: AppTheme.bodyLarge,
                    ),
                    Text(
                      '₹${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
