import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/workflow.dart';
import '../services/incident_service.dart';
import '../ui/call_widgets.dart';

class RepairIncidentPage extends StatefulWidget {
  const RepairIncidentPage({
    super.key,
    required this.actor,
    required this.incidentId,
    this.db,
  });
  final FactoryUser actor;
  final String incidentId;
  final FirebaseFirestore? db;
  @override
  State<RepairIncidentPage> createState() => _RepairIncidentPageState();
}

class _RepairIncidentPageState extends State<RepairIncidentPage> {
  final _notes = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _running = false;
  bool _saving = false;
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (!_running) {
      showFailure(context, const WorkflowException('notRunning'));
      return;
    }
    setState(() => _saving = true);
    try {
      await IncidentService(widget.db ?? FirebaseFirestore.instance).transition(
        incidentId: widget.incidentId,
        actor: widget.actor,
        to: 'resolved',
        message: _notes.text,
        machineRunning: _running,
      );
      if (mounted) Navigator.pop(context);
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
          title: SessionTitle(title: t.resolveCall, actor: widget.actor),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.resolveHelp),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _notes,
                      enabled: !_saving,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 1500,
                      decoration: InputDecoration(labelText: t.resolutionNotes),
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? t.errorNote : null,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.runningConfirmed),
                      value: _running,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _running = v ?? false),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(t.resolveCall),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
