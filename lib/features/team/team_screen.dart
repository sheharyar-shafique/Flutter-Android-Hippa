import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/team_api.dart';
import '../../core/theme/app_theme.dart';

const _kPurple = Color(0xFFA855F7);
const _kPurpleGrad = LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF7C3AED)]);

final _teamProvider = FutureProvider.autoDispose<Team?>((ref) => ref.watch(teamApiProvider).getTeam());

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(_teamProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(child: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kPurple)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.white))),
        data: (team) => team == null ? _NoTeamView(ref: ref) : _TeamView(team: team, ref: ref),
      )),
    );
  }
}

class _NoTeamView extends StatelessWidget {
  final WidgetRef ref;
  const _NoTeamView({required this.ref});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(color: _kPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.groups, color: _kPurple, size: 40)),
        const SizedBox(height: 16),
        const Text('No team yet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Create a team to invite colleagues and collaborate.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.slate400, fontSize: 13)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () async {
            final name = await _showRenameDialog(context, '');
            if (name != null && name.isNotEmpty) {
              await ref.read(teamApiProvider).createTeam(name);
              ref.invalidate(_teamProvider);
            }
          },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), decoration: BoxDecoration(gradient: _kPurpleGrad, borderRadius: BorderRadius.circular(14)),
            child: const Text('+ Create Team', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
          child: const Text('Back to Dashboard', style: TextStyle(color: AppColors.slate400))),
      ],
    )));
  }
}

class _TeamView extends StatelessWidget {
  final Team team;
  final WidgetRef ref;
  const _TeamView({required this.team, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
      // Header
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
          child: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18)),
        ),
        const SizedBox(width: 12),
        Container(width: 44, height: 44, decoration: BoxDecoration(gradient: _kPurpleGrad, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.groups, color: Colors.white, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Team Management', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          const Text('Invite colleagues, manage seats, and collaborate on notes', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
        ])),
      ]),
      const SizedBox(height: 10),
      // Buttons row
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        _HeaderBtn(icon: Icons.edit, label: 'Rename', onTap: () async {
          final name = await _showRenameDialog(context, team.name);
          if (name != null && name.isNotEmpty) {
            await ref.read(teamApiProvider).renameTeam(team.id, name);
            ref.invalidate(_teamProvider);
          }
        }),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final email = await _showInviteDialog(context, team.seatsUsed, team.memberLimit);
            if (email != null && email.isNotEmpty) {
              try {
                await ref.read(teamApiProvider).inviteMember(team.id, email);
                ref.invalidate(_teamProvider);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.emerald500, content: Text('Invite sent to $email', style: const TextStyle(color: Colors.white)), behavior: SnackBarBehavior.floating));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.danger, content: Text('$e', style: const TextStyle(color: Colors.white)), behavior: SnackBarBehavior.floating));
              }
            }
          },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9), decoration: BoxDecoration(gradient: _kPurpleGrad, borderRadius: BorderRadius.circular(10)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_add_alt, color: Colors.white, size: 15), SizedBox(width: 5), Text('Invite Member', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))])),
        ),
      ]),
      const SizedBox(height: 16),
      // Stats
      Row(children: [
        _Stat(label: 'Team Name', value: team.name, color: _kPurple, icon: Icons.groups),
        const SizedBox(width: 8),
        _Stat(label: 'Seats Used', value: '${team.seatsUsed} / ${team.memberLimit}', color: AppColors.emerald400, icon: Icons.event_seat),
        const SizedBox(width: 8),
        _Stat(label: 'Active Members', value: '${team.activeCount}', color: const Color(0xFF22C55E), icon: Icons.check_circle_outline),
        const SizedBox(width: 8),
        _Stat(label: 'Pending Invites', value: '${team.pendingCount}', color: const Color(0xFFF59E0B), icon: Icons.access_time),
      ]),
      const SizedBox(height: 24),
      // Members
      const Row(children: [Icon(Icons.people_alt_outlined, color: Colors.white, size: 18), SizedBox(width: 8), Text('Members', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 12),
      if (team.members.isEmpty)
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x14FFFFFF))),
          child: const Center(child: Text('No members yet. Invite your first colleague!', style: TextStyle(color: AppColors.slate400, fontSize: 13)))),
      ...team.members.map((m) => _MemberCard(member: m, teamId: team.id, ref: ref)),
      const SizedBox(height: 24),
      // Danger Zone
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)), color: AppColors.danger.withValues(alpha: 0.06)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Danger Zone', style: TextStyle(color: AppColors.danger, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Disbanding the team removes all members permanently.', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.slate800, title: const Text('Disband Team?', style: TextStyle(color: Colors.white)), content: const Text('This will remove all members. This cannot be undone.', style: TextStyle(color: AppColors.slate400)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Disband', style: TextStyle(color: AppColors.danger)))]));
              if (ok == true) {
                await ref.read(teamApiProvider).disbandTeam(team.id);
                ref.invalidate(_teamProvider);
              }
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withValues(alpha: 0.5))),
              child: const Text('Disband Team', style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w700))),
          ),
        ]),
      ),
    ]);
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: AppColors.slate300, size: 14), const SizedBox(width: 5), Text(label, style: const TextStyle(color: AppColors.slate300, fontSize: 12, fontWeight: FontWeight.w600))])));
}

class _Stat extends StatelessWidget {
  final String label, value; final Color color; final IconData icon;
  const _Stat({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x14FFFFFF))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 12), const SizedBox(width: 4), Flexible(child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
    ])));
}

class _MemberCard extends StatelessWidget {
  final TeamMember member; final String teamId; final WidgetRef ref;
  const _MemberCard({required this.member, required this.teamId, required this.ref});
  @override
  Widget build(BuildContext context) {
    final initial = (member.name ?? member.email)[0].toUpperCase();
    final isPending = member.status == 'pending';
    final statusColor = isPending ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x14FFFFFF))),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.slate700, shape: BoxShape.circle),
          child: Center(child: Text(initial, style: const TextStyle(color: AppColors.slate300, fontSize: 17, fontWeight: FontWeight.w700)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.name ?? member.email.split('@')[0], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(member.email, style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
          if (member.specialty != null) Text(member.specialty!, style: const TextStyle(color: AppColors.slate500, fontSize: 11)),
        ])),
        // Status badge
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isPending ? Icons.access_time : Icons.check_circle, color: statusColor, size: 12), const SizedBox(width: 4), Text(isPending ? 'Pending' : 'Active', style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700))])),
        const SizedBox(width: 6),
        // Copy email
        GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: member.email)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email copied'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); },
          child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.copy, color: AppColors.slate400, size: 14))),
        const SizedBox(width: 4),
        // Remove
        GestureDetector(onTap: () async {
          final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.slate800, title: const Text('Remove member?', style: TextStyle(color: Colors.white)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: AppColors.danger)))]));
          if (ok == true) { await ref.read(teamApiProvider).removeMember(teamId, member.id); ref.invalidate(_teamProvider); }
        }, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline, color: AppColors.slate400, size: 14))),
      ]),
    );
  }
}

// ── Dialogs ──

Future<String?> _showRenameDialog(BuildContext context, String currentName) {
  final ctrl = TextEditingController(text: currentName);
  return showDialog<String>(context: context, builder: (ctx) => Dialog(
    backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 28),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Rename Team', style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w800)),
        GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, color: Colors.black45, size: 20)),
      ]),
      const SizedBox(height: 16),
      const Text('New Team Name', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, autofocus: true, style: const TextStyle(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPurple, width: 1.5)))),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.w600))),
        const SizedBox(width: 10),
        GestureDetector(onTap: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12), decoration: BoxDecoration(gradient: _kPurpleGrad, borderRadius: BorderRadius.circular(12)),
            child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)))),
      ]),
    ])),
  ));
}

Future<String?> _showInviteDialog(BuildContext context, int seatsUsed, int maxSeats) {
  final ctrl = TextEditingController();
  return showDialog<String>(context: context, builder: (ctx) => Dialog(
    backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 28),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Invite Team Member', style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w800)),
        GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, color: Colors.black45, size: 20)),
      ]),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _kPurple.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [Icon(Icons.email_outlined, color: _kPurple.withValues(alpha: 0.5), size: 18), const SizedBox(width: 8), const Flexible(child: Text('An invite email will be sent to this address automatically.', style: TextStyle(color: Colors.black45, fontSize: 12)))])),
      const SizedBox(height: 16),
      const Text('Email Address', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, autofocus: true, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(hintText: 'colleague@clinic.com', hintStyle: TextStyle(color: Colors.grey.shade400), filled: true, fillColor: Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPurple, width: 1.5)))),
      const SizedBox(height: 8),
      Text('$seatsUsed of $maxSeats seats used', style: const TextStyle(color: Colors.black38, fontSize: 12)),
      const SizedBox(height: 4),
      const Divider(),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.w600))),
        const SizedBox(width: 10),
        GestureDetector(onTap: () { if (ctrl.text.trim().contains('@')) Navigator.pop(ctx, ctrl.text.trim()); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12), decoration: BoxDecoration(gradient: _kPurpleGrad, borderRadius: BorderRadius.circular(12)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_add_alt, color: Colors.white, size: 16), SizedBox(width: 6), Text('Send Invite', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))]))),
      ]),
    ])),
  ));
}
