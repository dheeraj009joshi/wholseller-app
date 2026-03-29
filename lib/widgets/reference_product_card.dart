import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';

class ReferenceProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final Function(int) onUpdateQuantity;
  final int initialQuantity;
  /// Use for horizontal list (e.g. 170). Null = fill parent (grid).
  final double? width;

  const ReferenceProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onUpdateQuantity,
    this.initialQuantity = 0,
    this.width,
  });

  @override
  State<ReferenceProductCard> createState() => _ReferenceProductCardState();
}

class _ReferenceProductCardState extends State<ReferenceProductCard> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  @override
  void didUpdateWidget(ReferenceProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuantity != oldWidget.initialQuantity) {
      _quantity = widget.initialQuantity;
    }
  }

  void _increment() {
    setState(() => _quantity++);
    widget.onUpdateQuantity(_quantity);
  }

  void _decrement() {
    if (_quantity > 0) {
      setState(() => _quantity--);
      widget.onUpdateQuantity(_quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product['images'] as List<dynamic>?;
    final imageUrl = images != null && images.isNotEmpty ? images[0] as String : '';
    final tiers = widget.product['pricing_tiers'] as Map<String, dynamic>?;
    double price = 0.0;
    if (tiers != null && tiers.isNotEmpty) {
      price = ((tiers['unit'] ?? tiers['1+ units'] ?? tiers.values.first) as num).toDouble();
    }
    final mrp = price > 0 ? price * 1.3 : 0.0;

    return Container(
      width: widget.width ?? double.infinity,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          // Offer Badge
          Positioned(
            top: 12,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Text(
                'OFFER',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
          InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Image
                  Expanded(
                    child: Center(
                      child: Hero(
                        tag: 'prod_${widget.product['id']}',
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.medication, size: 48, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.medication_liquid_rounded, size: 60, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    widget.product['name'] ?? 'Product Name',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    widget.product['dosage'] ?? 'N/A',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  
                  // Price Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${mrp.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400], decoration: TextDecoration.lineThrough),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Add / Quantity Controls
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: _quantity == 0
                        ? OutlinedButton(
                            onPressed: _increment,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.greenColor, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: AppTheme.greenColor.withOpacity(0.02),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: const Text(
                                'Add to Cart',
                                style: TextStyle(color: AppTheme.greenColor, fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: AppTheme.greenColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: AppTheme.greenColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 20),
                                  onPressed: _decrement,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                  onPressed: _increment,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
