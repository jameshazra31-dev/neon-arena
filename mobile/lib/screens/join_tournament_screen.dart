import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/profile_service.dart';
import '../services/tournament_service.dart';
import '../widgets/widgets.dart';

class JoinTournamentScreen extends StatefulWidget {
  final Tournament tournament;
  const JoinTournamentScreen({super.key, required this.tournament});
  @override
  State<JoinTournamentScreen> createState() => _JoinTournamentScreenState();
}

class _JoinTournamentScreenState extends State<JoinTournamentScreen> {
  int _step = 0;
  final _uid = TextEditingController(), _ign = TextEditingController(), _utr = TextEditingController(), _promo = TextEditingController();
  File? _screenshot;
  bool _busy = false;

  @override
  void initState() { super.initState(); _prefillGameProfile(); }

  Future<void> _prefillGameProfile() async {
    final profiles = await ProfileService.gameProfiles();
    final match = profiles.where((p) => p.game == widget.tournament.game);
    if (match.isNotEmpty && mounted) setState(() { _uid.text = match.first.gameUid; _ign.text = match.first.teamName ?? match.first.ign; });
  }

  Future<void> _pickScreenshot() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _screenshot = File(picked.path));
  }

  Future<void> _submit() async {
    final t = widget.tournament;
    final isFree = t.entryFee == 0;
    if (_uid.text.trim().isEmpty || _ign.text.trim().isEmpty) { _snack('Please fill your game ID and IGN'); return; }
    if (!isFree && (_screenshot == null || _utr.text.trim().isEmpty)) { _snack('Upload screenshot and enter UTR number'); return; }
    setState(() => _busy = true);
    try {
      String screenshotPath = '';
      if (!isFree) screenshotPath = await ProfileService.uploadPaymentScreenshot(_screenshot!, t.id);
      await TournamentService.join(tournamentId: t.id, gameUid: _uid.text.trim(), ign: _ign.text.trim(), utr: _utr.text.trim(), screenshotUrl: screenshotPath, promoCode: _promo.text.trim().isEmpty ? null : _promo.text.trim());
      await ProfileService.upsertGameProfile(game: t.game, gameUid: _uid.text.trim(), ign: _ign.text.trim(), teamName: Games.usesTeamName(t.game) ? _ign.text.trim() : null);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text(isFree ? 'You are in!' : 'Request submitted'),
        content: Text(isFree ? 'Free entry confirmed. Room details will appear before the match.' : 'Payment under review. You will get notified once admin approves.'),
        actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('OK'))],
      ));
    } catch (e) { _snack(e.toString()); } finally { if (mounted) setState(() => _busy = false); }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final isFree = t.entryFee == 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Join Tournament')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () { if (_step < (isFree ? 0 : 2)) { setState(() => _step += 1); } else { _submit(); } },
        onStepCancel: _step == 0 ? null : () => setState(() => _step -= 1),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(children: [
            Expanded(child: NeonButton(label: _step == (isFree ? 0 : 2) ? 'SUBMIT REQUEST' : 'CONTINUE', loading: _busy, onPressed: details.onStepContinue)),
            if (details.onStepCancel != null) TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
          ]),
        ),
        steps: [
          Step(
            title: const Text('Confirm your game ID'),
            isActive: _step >= 0,
            content: Column(children: [
              TextField(controller: _uid, decoration: InputDecoration(labelText: '${Games.label(t.game)} UID / ID')),
              const SizedBox(height: 12),
              TextField(controller: _ign, decoration: InputDecoration(labelText: Games.usesTeamName(t.game) ? 'Team Name' : 'In-Game Name (IGN)')),
            ]),
          ),
          if (!isFree) Step(
            title: Text('Pay entry fee - Rs.${t.entryFee.toStringAsFixed(0)}'),
            isActive: _step >= 1,
            content: GlassCard(child: Column(children: [
              if (t.upiQrUrl != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: t.upiQrUrl!, height: 220))
              else const Icon(Icons.qr_code_2, size: 140, color: NeonColors.blue),
              const SizedBox(height: 10),
              SelectableText(t.upiId ?? 'UPI ID not set', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Scan QR or pay to UPI ID above, then continue.', textAlign: TextAlign.center, style: TextStyle(color: NeonColors.textMuted)),
              const SizedBox(height: 12),
              TextField(controller: _promo, decoration: const InputDecoration(labelText: 'Promo code (optional)')),
            ])),
          ),
          if (!isFree) Step(
            title: const Text('Upload payment proof'),
            isActive: _step >= 2,
            content: Column(children: [
              GestureDetector(
                onTap: _pickScreenshot,
                child: Container(
                  height: 160, width: double.infinity,
                  decoration: BoxDecoration(color: NeonColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: NeonColors.blue.withOpacity(.4)), image: _screenshot == null ? null : DecorationImage(image: FileImage(_screenshot!), fit: BoxFit.cover)),
                  child: _screenshot == null ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload_file, size: 40, color: NeonColors.blue), SizedBox(height: 8), Text('Tap to upload payment screenshot')]) : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: _utr, decoration: const InputDecoration(labelText: 'UTR / Transaction ID', helperText: '12-digit reference from your UPI app. Reused UTRs are auto-rejected.')),
            ]),
          ),
        ],
      ),
    );
  }
}
