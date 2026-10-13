import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/workflow.dart';
import '../services/test_feedback_service.dart';
import '../ui/call_widgets.dart';

class TestFeedbackPage extends StatefulWidget {
  const TestFeedbackPage({super.key, required this.actor, required this.db});
  final FactoryUser actor;
  final FirebaseFirestore db;

  @override
  State<TestFeedbackPage> createState() => _TestFeedbackPageState();
}

class _TestFeedbackPageState extends State<TestFeedbackPage> {
  final _form = GlobalKey<FormState>();
  final _notes = TextEditingController();
  late final _service = TestFeedbackService(widget.db);
  late final _id = _service.records(widget.actor.companyId).doc().id;
  int? _ease;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.submit(
        id: _id,
        actor: widget.actor,
        ease: _ease!,
        notes: _notes.text,
        locale: AppLocalizations.of(context).localeName,
      );
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: SessionTitle(title: t.testFeedback, actor: widget.actor),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(t.feedbackHelp),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                isExpanded: true,
                decoration: InputDecoration(labelText: t.feedbackEase),
                items: [
                  for (var n = 1; n <= 5; n++)
                    DropdownMenuItem(value: n, child: Text('$n / 5')),
                ],
                onChanged: _saving ? null : (value) => _ease = value,
                validator: (value) => value == null ? t.feedbackRequired : null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: Text(t.feedbackScale),
              ),
              TextFormField(
                controller: _notes,
                enabled: !_saving,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: t.feedbackNotes,
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? t.feedbackRequired : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(t.feedbackSend),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
