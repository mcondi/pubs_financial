import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'models/feedback_models.dart';
import 'providers/feedback_providers.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  FeedbackType _type = FeedbackType.bug;
  FeedbackSeverity _severity = FeedbackSeverity.medium;
  bool _anonymous = false;

  final List<File> _files = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ---- attachments helpers ----

  bool _isImageFile(File f) {
    final p = f.path.toLowerCase();
    return p.endsWith('.png') || p.endsWith('.jpg') || p.endsWith('.jpeg') || p.endsWith('.heic') || p.endsWith('.webp');
  }

  void _addFiles(List<File> newFiles) {
    // De-dupe by path
    final existing = _files.map((f) => f.path).toSet();
    final toAdd = newFiles.where((f) => !existing.contains(f.path)).toList();
    if (toAdd.isEmpty) return;

    setState(() => _files.addAll(toAdd));
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (result == null) return;

    final picked = result.files
        .where((f) => f.path != null)
        .map((f) => File(f.path!))
        .toList();

    if (!mounted) return;
    _addFiles(picked);
  }

  Future<void> _takePhoto() async {
    try {
      final x = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (x == null) return;
      if (!mounted) return;
      _addFiles([File(x.path)]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final xs = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (xs.isEmpty) return;
      if (!mounted) return;
      _addFiles(xs.map((x) => File(x.path)).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo picker error: $e')),
      );
    }
  }

  Future<void> _showAttachmentSheet() async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final disabled = ref.read(feedbackSubmitProvider).isSubmitting;

        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: disabled
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _takePhoto();
                      },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from photos'),
                onTap: disabled
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _pickFromGallery();
                      },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Choose file'),
                onTap: disabled
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _pickFiles();
                      },
              ),
              if (_files.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear attachments'),
                  onTap: disabled
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          setState(() => _files.clear());
                        },
                ),
            ],
          ),
        );
      },
    );
  }

  void _removeFileAt(int index) {
    setState(() => _files.removeAt(index));
  }

  // ---- submit ----

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    await ref.read(feedbackSubmitProvider.notifier).submit(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          type: _type,
          severity: _severity,
          isAnonymous: _anonymous,
          reporterName: _anonymous ? null : _nameCtrl.text.trim(),
          reporterEmail: _anonymous ? null : _emailCtrl.text.trim(),
          attachments: _files,
        );

    final state = ref.read(feedbackSubmitProvider);
    if (!mounted) return;

    if (state.result != null) {
      final publicId = state.result!.publicId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publicId != null ? 'Feedback submitted (#$publicId)' : 'Feedback submitted'),
        ),
      );

      // Reset
      ref.read(feedbackSubmitProvider.notifier).reset();
      setState(() {
        _titleCtrl.clear();
        _descCtrl.clear();
        _nameCtrl.clear();
        _emailCtrl.clear();
        _type = FeedbackType.bug;
        _severity = FeedbackSeverity.medium;
        _anonymous = false;
        _files.clear();
      });
    } else if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: ${state.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(feedbackSubmitProvider);

  return Scaffold(
  backgroundColor: Colors.white,
  appBar: AppBar(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.white,
  elevation: 0,

  // ✅ THIS is the missing piece
  leadingWidth: 44,

  automaticallyImplyLeading: false,
  centerTitle: true,

  leading: IconButton(
    icon: const Icon(
      Icons.arrow_back_ios_new,
      color: Colors.black,
      size: 20,
    ),
    onPressed: () {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        context.go('/');
      }
    },
  ),

  title: const Text(
    'Feedback',
    style: TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
  ),
),

  body: SafeArea(
    child: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          // 👇 keep your existing form fields exactly as they are

              DropdownButtonFormField<FeedbackType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: FeedbackType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: submitState.isSubmitting ? null : (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FeedbackSeverity>(
                initialValue: _severity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: FeedbackSeverity.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: submitState.isSubmitting ? null : (v) => setState(() => _severity = v ?? _severity),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                enabled: !submitState.isSubmitting,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.trim().length < 3) return 'Title is too short';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                enabled: !submitState.isSubmitting,
                maxLines: 6,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required';
                  if (v.trim().length < 10) return 'Please add a bit more detail';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                value: _anonymous,
                onChanged: submitState.isSubmitting ? null : (v) => setState(() => _anonymous = v),
                title: const Text('Submit anonymously'),
                contentPadding: EdgeInsets.zero,
              ),
              if (!_anonymous) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  enabled: !submitState.isSubmitting,
                  decoration: const InputDecoration(labelText: 'Your name (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !submitState.isSubmitting,
                  decoration: const InputDecoration(labelText: 'Your email (optional)'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],

              const SizedBox(height: 16),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: submitState.isSubmitting ? null : _showAttachmentSheet,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add attachment'),
                  ),
                  const SizedBox(width: 12),
                  Text('${_files.length} selected'),
                ],
              ),

              if (_files.isNotEmpty) ...[
                const SizedBox(height: 12),

                // thumbnails row for images
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _files.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final f = _files[i];
                      final name = f.path.split(Platform.pathSeparator).last;

                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 84,
                              height: 84,
                              color: Colors.black.withValues(alpha: 0.06),
                              child: _isImageFile(f)
                                  ? Image.file(f, fit: BoxFit.cover)
                                  : Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: InkWell(
                              onTap: submitState.isSubmitting ? null : () => _removeFileAt(i),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                // also show file list for clarity
                ..._files.asMap().entries.map((e) {
                  final idx = e.key;
                  final f = e.value;
                  final name = f.path.split(Platform.pathSeparator).last;

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: submitState.isSubmitting ? null : () => _removeFileAt(idx),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),

              if (submitState.isSubmitting) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
              ],

              ElevatedButton(
                onPressed: submitState.isSubmitting ? null : _submit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
