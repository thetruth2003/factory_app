import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/workflow.dart';
import '../ui/call_widgets.dart';

class NoteSubmission {
  const NoteSubmission(this.message, this.team);
  final String message;
  final String? team;
}

class NoteDialog extends StatefulWidget {
  const NoteDialog({super.key, this.waiting = false});
  final bool waiting;
  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();
  String _team = 'maintenance';
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.waiting ? t.waitingReason : t.addNote),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.waiting) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _team,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t.team),
                    items: Workflow.teams
                        .map(
                          (team) => DropdownMenuItem(
                            value: team,
                            child: Text(teamLabel(t, team)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _team = value!),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1500,
                  decoration: InputDecoration(hintText: t.noteHint),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? t.errorNote : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(
                context,
                NoteSubmission(
                  _controller.text.trim(),
                  widget.waiting ? _team : null,
                ),
              );
            }
          },
          child: Text(t.send),
        ),
      ],
    );
  }
}
