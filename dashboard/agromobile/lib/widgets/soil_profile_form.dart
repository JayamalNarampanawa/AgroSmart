import 'package:flutter/material.dart';

import '../models/farm_profile.dart';

class SoilProfileForm extends StatefulWidget {
  final FarmProfile profile;
  final ValueChanged<FarmProfile> onSave;

  const SoilProfileForm({super.key, required this.profile, required this.onSave});

  @override
  State<SoilProfileForm> createState() => _SoilProfileFormState();
}

class _SoilProfileFormState extends State<SoilProfileForm> {
  late TextEditingController nController;
  late TextEditingController pController;
  late TextEditingController kController;
  late TextEditingController phController;

  @override
  void initState() {
    super.initState();
    nController = TextEditingController(text: widget.profile.n.toStringAsFixed(0));
    pController = TextEditingController(text: widget.profile.p.toStringAsFixed(0));
    kController = TextEditingController(text: widget.profile.k.toStringAsFixed(0));
    phController = TextEditingController(text: widget.profile.ph.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant SoilProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      nController.text = widget.profile.n.toStringAsFixed(0);
      pController.text = widget.profile.p.toStringAsFixed(0);
      kController.text = widget.profile.k.toStringAsFixed(0);
      phController.text = widget.profile.ph.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    nController.dispose();
    pController.dispose();
    kController.dispose();
    phController.dispose();
    super.dispose();
  }

  void _save() {
    final n = double.tryParse(nController.text.trim()) ?? widget.profile.n;
    final p = double.tryParse(pController.text.trim()) ?? widget.profile.p;
    final k = double.tryParse(kController.text.trim()) ?? widget.profile.k;
    final ph = double.tryParse(phController.text.trim()) ?? widget.profile.ph;
    final updated = FarmProfile(
      n: n,
      p: p,
      k: k,
      ph: ph,
      phIsDefault: ph == 6.5,
    );
    widget.onSave(updated);
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NPK and pH',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nController,
                decoration: _fieldDecoration('Nitrogen (N)'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: pController,
                decoration: _fieldDecoration('Phosphorus (P)'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: kController,
                decoration: _fieldDecoration('Potassium (K)'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: phController,
                decoration: _fieldDecoration('pH'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
              child: const Text('Save', style: TextStyle(color: Color(0xFF041018))),
            ),
            const SizedBox(width: 10),
            Text(
              widget.profile.phIsDefault ? 'pH: Default' : 'pH: Updated',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ],
        ),
      ],
    );
  }
}
