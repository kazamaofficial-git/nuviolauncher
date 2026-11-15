import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/color_ext.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/page_header.dart';
import '../../data/models/announcement.dart';
import 'news_controller.dart';

/// List of announcements published from the admin console.
class AnnouncementsCard extends StatelessWidget {
  const AnnouncementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final news = context.watch<NewsController>();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle('Announcements', icon: Icons.campaign_outlined)),
              IconButton(
                tooltip: 'Refresh',
                onPressed: news.loading ? null : news.refresh,
                icon: news.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (news.announcements.isEmpty)
            Text(
              news.error ?? 'No announcements right now.',
              style: const TextStyle(color: AppColors.textMuted),
            )
          else
            for (final a in news.announcements) _AnnouncementTile(item: a),
        ],
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item});

  final Announcement item;

  Color get _color {
    switch (item.level) {
      case 'warning':
        return AppColors.warning;
      case 'success':
        return AppColors.success;
      default:
        return AppColors.lavender;
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = item.createdAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _color.fade(0.08),
        border: Border(left: BorderSide(color: _color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(item.body, style: const TextStyle(color: AppColors.textMuted)),
          if (created != null) ...[
            const SizedBox(height: 6),
            Text(
              formatDate(created),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
