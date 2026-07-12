import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/bengo_app_bar.dart';

class WordDetailScreen extends StatelessWidget {
  final String japanese;
  final String english;
  final String romaji;

  const WordDetailScreen({
    super.key,
    this.japanese = 'こんにちは',
    this.english = 'Hello',
    this.romaji = 'Konnichiwa',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context)),
            SliverToBoxAdapter(child: _buildWordSection()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildMnemonicCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildCommunityHints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return const BenGoAppBar(showBack: true);
  }

  Widget _buildWordSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          Text(
            japanese,
            style: GoogleFonts.notoSansJp(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: AppColors.accentGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Audio button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)
              ],
            ),
            child: const Icon(Icons.volume_up_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 12),
          Text(english, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text(romaji, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildMnemonicCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MY PERSONAL MNEMONIC', style: AppTextStyles.captionUpper),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              '"Konnichiwa... \'Can I watch\' ya learn Japanese?"',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityHints() {
    final hints = [
      {
        'avatar': '⭐',
        'text': '"Sounds like \'can each of ya\' say hi!"',
        'isPrimary': true
      },
      {
        'avatar': '👤',
        'text': '"こんにちは is such a classic greeting!"',
        'isPrimary': false
      },
      {
        'avatar': '👤',
        'text': '"Always makes me smile to hear this."',
        'isPrimary': false
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COMMUNITY HINTS', style: AppTextStyles.captionUpper),
                  Text('(4)', style: AppTextStyles.bodySmall),
                ],
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                label: Text(
                  'ADD\nYOURS',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...hints.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: h['isPrimary'] as bool
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.bgLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: h['isPrimary'] as bool
                              ? AppColors.primary
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Center(child: Text(h['avatar'] as String)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: h['isPrimary'] as bool
                              ? AppColors.primary.withOpacity(0.06)
                              : AppColors.bgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: h['isPrimary'] as bool
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          h['text'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: h['isPrimary'] as bool
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
