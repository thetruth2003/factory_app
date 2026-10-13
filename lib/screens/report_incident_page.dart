import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/workflow.dart';
import '../models/call_reasons.dart';
import '../services/incident_service.dart';
import '../services/photo_service.dart';
import '../ui/call_widgets.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({
    super.key,
    required this.actor,
    required this.machineId,
    required this.machineKey,
    this.db,
  });
  final FactoryUser actor;
  final String machineId;
  final String machineKey;
  final FirebaseFirestore? db;
  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _code = TextEditingController();
  late final _db = widget.db ?? FirebaseFirestore.instance;
  PhotoService? _photosService;
  PhotoService get _photoSvc =>
      _photosService ??= PhotoService(_db, FirebaseStorage.instance);
  String _kind = 'fault';
  String? _reason;
  String? _suggestedDescription;
  String _team = 'operator';
  bool? _stopped;
  bool _busy = false;
  String? _createdId;
  bool _photoError = false;
  final List<XFile> _photos = [];
  @override
  void dispose() {
    _description.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _pick(bool camera) async {
    try {
      final files = camera
          ? [await _photoSvc.pickSingle()].whereType<XFile>().toList()
          : await _photoSvc.pickMultiple();
      if (!mounted) return;
      if (files.length + _photos.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).photoLimit)),
        );
      }
      setState(() => _photos.addAll(files.take(5 - _photos.length)));
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _submit() async {
    if (_busy || (_createdId == null && !_form.currentState!.validate())) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (_createdId == null) {
        final result = await IncidentService(_db).createIncident(
          actor: widget.actor,
          machineId: widget.machineId,
          machineKey: widget.machineKey,
          description: _description.text,
          kind: _kind,
          targetTeam: _team,
          productionStopped: _stopped!,
          reportedAt: DateTime.now(),
          errorCode: _code.text,
          reasonCode: _reason,
        );
        if (!mounted) return;
        if (!result.created) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).existingCall)),
          );
          Navigator.pop(context, result.incidentId);
          return;
        }
        _createdId = result.incidentId;
      }
      if (_photos.isNotEmpty) {
        try {
          await _photoSvc.uploadIncidentPhotos(
            incidentId: _createdId!,
            byUid: widget.actor.uid,
            byName: widget.actor.name,
            byRole: widget.actor.role,
            files: _photos,
          );
        } catch (_) {
          if (mounted) setState(() => _photoError = true);
          return;
        }
      }
      if (mounted) Navigator.pop(context, _createdId);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locked = _busy || _createdId != null;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: SessionTitle(title: t.newCall, actor: widget.actor),
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
                    Text(
                      widget.machineKey,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('${t.summaryReportedBy}: ${widget.actor.name}'),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: _kind,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: t.kind),
                      items: Workflow.kinds
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(kindLabel(t, v)),
                            ),
                          )
                          .toList(),
                      onChanged: locked
                          ? null
                          : (v) => setState(() {
                              _kind = v!;
                              _reason = null;
                              if (_description.text == _suggestedDescription) {
                                _description.clear();
                              }
                              _suggestedDescription = null;
                            }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.quickReason,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final code in CallReasons.byKind[_kind]!)
                          ChoiceChip(
                            label: Text(reasonLabel(t, code)),
                            selected: _reason == code,
                            onSelected: locked
                                ? null
                                : (selected) => setState(() {
                                    _reason = selected ? code : null;
                                    if (_description.text.trim().isEmpty ||
                                        _description.text ==
                                            _suggestedDescription) {
                                      _suggestedDescription = selected
                                          ? reasonLabel(t, code)
                                          : null;
                                      _description.text =
                                          _suggestedDescription ?? '';
                                    }
                                  }),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Text(t.quickReasonHelp),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _team,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: t.team),
                      items: Workflow.teams
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(teamLabel(t, v)),
                            ),
                          )
                          .toList(),
                      onChanged: locked
                          ? null
                          : (v) => setState(() => _team = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<bool>(
                      initialValue: _stopped,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: t.productionState),
                      items: [
                        DropdownMenuItem(
                          value: false,
                          child: Text(t.productionRunning),
                        ),
                        DropdownMenuItem(
                          value: true,
                          child: Text(t.productionStopped),
                        ),
                      ],
                      onChanged: locked
                          ? null
                          : (v) => setState(() => _stopped = v),
                      validator: (v) => v == null ? t.choose : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _description,
                      enabled: !locked,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1500,
                      decoration: InputDecoration(labelText: t.callDescription),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? t.errorNote : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _code,
                      enabled: !locked,
                      maxLength: 40,
                      decoration: InputDecoration(labelText: t.codeOptional),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.photoOptional,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: locked || _photos.length >= 5
                              ? null
                              : () => _pick(true),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(t.camera),
                        ),
                        OutlinedButton.icon(
                          onPressed: locked || _photos.length >= 5
                              ? null
                              : () => _pick(false),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(t.gallery),
                        ),
                      ],
                    ),
                    if (_photos.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_photos[index].path),
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (!locked)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton.filled(
                                    onPressed: () =>
                                        setState(() => _photos.removeAt(index)),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (_photoError) ...[
                      const SizedBox(height: 16),
                      Text(t.photosPartial),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.pop(context, _createdId),
                        child: Text(t.openCall),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _submit,
                        icon: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          _createdId == null ? t.send : t.retryPhotos,
                        ),
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
