import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/widgets.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  List<GameProfile> _gameProfiles = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final results = await Future.wait([ProfileService.me(), ProfileService.gameProfiles()]);
    if (!mounted) return;
    setState(() { _profile = results[0] as Profile; _gameProfiles = results[1] as List<GameProfile>; });
  }

  Future<void> _changeAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    await ProfileService.uploadAvatar(File(picked.path));
    _load();
  }

  Future<void> _editGameProfile(String game) async {
    final existing = _gameProfiles.where((p) => p.game == game).firstOrNull;
    final uid = TextEditingController(text: existing?.gameUid);
    final ign = TextEditingController(text: Games.usesTeamName(game) ? existing?.teamName : existing?.ign);
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('${Games.emoji(game)} ${Games.label(game)}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: uid, decoration: const InputDecoration(labelText: 'UID / Game ID')),
        const SizedBox(height: 12),
        TextField(controller: ign, decoration: InputDecoration(labelText: Games.usesTeamName(game) ? 'Team Name' : 'In-Game Name (IGN)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            await ProfileService.upsertGameProfile(game: game, gameUid: uid.text.trim(), ign: ign.text.trim(), teamName: Games.usesTeamName(game) ? ign.text.trim() : null);
            if (context.mounted) Navigator.pop(context);
            _load();
          },
          child: const Text('Save'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Stack(children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: NeonColors.purple.withOpacity(.3),
            backgroundImage: p.avatarUrl == null ? null : CachedNetworkImageProvider(p.avatarUrl!),
            child: p.avatarUrl == null ? Text(p.username.isEmpty ? '?' : p.username[0].toUpperCase(), style: const TextStyle(fontSize: 34)) : null,
          ),
          Positioned(right: 0, bottom: 0, child: GestureDetector(
            onTap: _changeAvatar,
            child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(gradient: NeonColors.neonGradient, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 16)),
          )),
        ])),
        const SizedBox(height: 12),
        Center(child: Text(p.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
        if (p.phone != null) Center(child: Text(p.phone!, style: const TextStyle(color: NeonColors.textMuted))),
        const SizedBox(height: 20),
        GlassCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(children: [
            const Text('WALLET', style: TextStyle(color: NeonColors.textMuted, fontSize: 11, letterSpacing: 2)),
            Text('Rs.${p.walletBalance.toStringAsFixed(0)}', style: const TextStyle(color: NeonColors.green, fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
          GestureDetector(
            onTap: () { Clipboard.setData(ClipboardData(text: p.referralCode)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied!'))); },
            child: Column(children: [
              const Text('REFERRAL CODE', style: TextStyle(color: NeonColors.textMuted, fontSize: 11, letterSpacing: 2)),
              Text('${p.referralCode} [copy]', style: const TextStyle(color: NeonColors.blue, fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          ),
        ])),
        const SizedBox(height: 20),
        const Text('GAME PROFILES', style: TextStyle(color: NeonColors.blue, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 8),
        for (final game in Games.all)
          Card(margin: const EdgeInsets.symmetric(vertical: 5), child: ListTile(
            leading: Text(Games.emoji(game), style: const TextStyle(fontSize: 26)),
            title: Text(Games.label(game), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Builder(builder: (_) {
              final gp = _gameProfiles.where((x) => x.game == game).firstOrNull;
              if (gp == null) return const Text('Not set up');
              return Text(Games.usesTeamName(game) ? '${gp.gameUid} - ${gp.teamName ?? ''}' : '${gp.gameUid} - ${gp.ign}');
            }),
            trailing: const Icon(Icons.edit, color: NeonColors.textMuted),
            onTap: () => _editGameProfile(game),
          )),
        const SizedBox(height: 20),
        NeonButton(
          label: 'LOG OUT',
          onPressed: () async {
            await AuthService.signOut();
            if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          },
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}
