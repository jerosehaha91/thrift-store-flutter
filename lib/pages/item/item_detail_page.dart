// lib/pages/item_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/supabase_service.dart';
import '../../models/item.dart';
import '../../widgets/info_chip.dart';
import 'full_screen_image_page.dart';

class ItemDetailPage extends StatelessWidget {
  final int itemId;
  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<SupabaseService>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BFA6), Color(0xFF00695C)], // 🌿 Fresh teal-green theme
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Item?>(
            future: svc.fetchItemDetail(itemId),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snap.error}',
                    style: GoogleFonts.robotoSlab(color: Colors.redAccent),
                  ),
                );
              }
              final item = snap.data;
              if (item == null) {
                return Center(
                  child: Text(
                    'Item not found 🤷',
                    style: GoogleFonts.robotoSlab(color: Colors.white),
                  ),
                );
              }

              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Back + store title with logo
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Image.asset(
                                'assets/logo.png', // ✅ Your logo file
                                height: 28,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Eco Thrift Store', // ✅ Store name updated
                                style: GoogleFonts.robotoSlab(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tappable image with Hero
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FullScreenImagePage(itemId: item.id, imageUrl: item.imageUrl),
                          ),
                        ),
                        child: Hero(
                          tag: 'item-image-${item.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              item.imageUrl,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title & price
                      Text(
                        item.title,
                        style: GoogleFonts.robotoSlab(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱ ${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.robotoSlab(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.amberAccent,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: GoogleFonts.robotoSlab(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: GoogleFonts.robotoSlab(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info chips
                      SizedBox(
                        height: 40,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              InfoChip(icon: Icons.person, text: item.uploadedBy),
                              const SizedBox(width: 8),
                              InfoChip(icon: Icons.contact_mail, text: item.contactInfo),
                              const SizedBox(width: 8),
                              InfoChip(
                                icon: Icons.calendar_today,
                                text:
                                '${item.createdAt.month}/${item.createdAt.day}/${item.createdAt.year}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Contact Owner button
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final email = snap.data!.contactInfo.trim();
                        final subject =
                        Uri.encodeComponent('Inquiry about "${item.title}"');
                        final uri = Uri.parse('mailto:$email?subject=$subject');
                        try {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } catch (_) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Contact Owner',
                                  style: GoogleFonts.robotoSlab()),
                              content: SelectableText(email,
                                  style: GoogleFonts.robotoSlab()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close',
                                      style: GoogleFonts.robotoSlab()),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Contact Owner',
                        style: GoogleFonts.robotoSlab(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
