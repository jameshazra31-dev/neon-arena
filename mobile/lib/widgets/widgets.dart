import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';

class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const NeonButton({super.key, required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : NeonColors.neonGradient,
        color: onPressed == null ? NeonColors.surface : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed == null ? [] : [BoxShadow(color: NeonColors.purple.withOpacity(.45), blurRadius: 18, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
            : Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0x8811121F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'approved' => (NeonColors.green, 'JOINED'),
      'pending' => (NeonColors.amber, 'PENDING'),
      'rejected' => (NeonColors.red, 'REJECTED'),
      'live' => (NeonColors.pink, 'LIVE'),
      'upcoming' => (NeonColors.blue, 'UPCOMING'),
      'completed' => (NeonColors.textMuted, 'COMPLETED'),
      _ => (NeonColors.textMuted, status.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.6)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;
  const TournamentCard({super.key, required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final df = DateFormat('EEE, d MMM - h:mm a');
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.bannerUrl != null)
              CachedNetworkImage(imageUrl: t.bannerUrl!, height: 140, width: double.infinity, fit: BoxFit.cover)
            else
              Container(
                height: 90, width: double.infinity,
                decoration: const BoxDecoration(gradient: NeonColors.neonGradient),
                alignment: Alignment.center,
                child: Text('${Games.emoji(t.game)} ${Games.label(t.game)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                  StatusChip(status: t.status),
                ]),
                const SizedBox(height: 6),
                Text(df.format(t.startTime), style: const TextStyle(color: NeonColors.textMuted)),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _stat('ENTRY', t.entryFee == 0 ? 'FREE' : '₹${t.entryFee.toStringAsFixed(0)}'),
                  _stat('PRIZE', '₹${t.prizePool.toStringAsFixed(0)}'),
                  _stat('SLOTS', '${t.availableSlots ?? '-'}/${t.totalSlots}'),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: NeonColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
      Text(value, style: const TextStyle(color: NeonColors.blue, fontSize: 16, fontWeight: FontWeight.w800)),
    ],
  );
}
