import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../providers/upload_provider.dart';
import '../../../../core/theme/app_theme.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // فرم
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  final _tagInputController = TextEditingController();

  String? _audioFilePath;
  String? _audioFileName;
  String? _coverPath;
  List<String> _tags = [];
  String _visibility = 'public';

  bool _showArtistSuggestions = false;
  bool _showTagSuggestions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _artistController.addListener(() {
      setState(() => _showArtistSuggestions = _artistController.text.length >= 2);
    });
    _tagInputController.addListener(() {
      setState(() => _showTagSuggestions = _tagInputController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _artistController.dispose();
    _descController.dispose();
    _urlController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      setState(() {
        _audioFilePath = file.path;
        _audioFileName = file.name;
        // عنوان رو از نام فایل بگیر اگه خالیه
        if (_titleController.text.isEmpty) {
          _titleController.text =
              file.name.replaceAll(RegExp(r'\.[^\.]+$'), '');
        }
      });
    }
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _coverPath = image.path);
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _tagInputController.clear();
        _showTagSuggestions = false;
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _submit() async {
    final isFile = _tabController.index == 0;

    if (isFile && _audioFilePath == null) {
      _showError('لطفاً یک فایل صوتی انتخاب کنید');
      return;
    }
    if (!isFile && _urlController.text.trim().isEmpty) {
      _showError('لطفاً لینک دانلود را وارد کنید');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showError('لطفاً عنوان آهنگ را وارد کنید');
      return;
    }

    // Capture all values before navigation
    final notifier = ref.read(uploadProvider.notifier);
    final filePath = _audioFilePath;
    final url = _urlController.text.trim();
    final title = _titleController.text.trim();
    final artistName = _artistController.text.trim();
    final coverPath = _coverPath;
    final tags = List<String>.from(_tags);
    final description = _descController.text.trim();
    final visibility = _visibility;

    // Navigate away first so user is not blocked
    if (mounted) context.go('/feed');

    // Start upload after navigation
    if (isFile) {
      unawaited(notifier.uploadFromFile(
        filePath: filePath!,
        title: title,
        artistName: artistName,
        coverPath: coverPath,
        tags: tags,
        description: description,
        visibility: visibility,
      ));
    } else {
      unawaited(notifier.uploadFromUrl(
        url: url,
        title: title,
        artistName: artistName,
        tags: tags,
        description: description,
        visibility: visibility,
      ));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('افزودن آهنگ'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: uploadState.status == UploadStatus.error
          ? _buildErrorView(uploadState)
          : _buildForm(),
    );
  }

  Widget _buildLoadingView(UploadState state) {
    String message;
    IconData icon;
    Color color;

    switch (state.status) {
      case UploadStatus.uploading:
        message = 'در حال ارسال به سرور...';
        icon = Icons.cloud_upload_rounded;
        color = AppColors.primary;
      case UploadStatus.uploading:
        message = 'در حال آپلود آهنگ...';
        icon = Icons.cloud_upload_rounded;
        color = AppColors.primary;
      case UploadStatus.processing:
        message = 'در حال پردازش صوت...';
        icon = Icons.equalizer_rounded;
        color = Colors.amber;
      default:
        message = 'لطفاً صبر کنید...';
        icon = Icons.hourglass_top_rounded;
        color = AppColors.darkTextSecondary;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.status == UploadStatus.processing
                    ? null
                    : state.progress,
                backgroundColor: AppColors.darkSurface,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            if (state.status != UploadStatus.processing) ...[
              const SizedBox(height: 12),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(UploadState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'خطا در آپلود',
              style: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error ?? 'خطای ناشناخته',
              style: const TextStyle(color: AppColors.darkTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(uploadProvider.notifier).reset(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab انتخاب روش
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.darkTextSecondary,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('انتخاب فایل'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('لینک دانلود'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // محتوای tab
          SizedBox(
            height: 120,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab فایل
                _buildFilePicker(),
                // Tab لینک
                _buildUrlInput(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cover Image
          _buildSectionTitle('کاور آهنگ', optional: true),
          const SizedBox(height: 10),
          _buildCoverPicker(),
          const SizedBox(height: 20),

          // عنوان
          _buildSectionTitle('عنوان آهنگ'),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.darkTextPrimary),
            decoration: _inputDecoration(
              hint: 'مثال: دلتنگی',
              icon: Icons.music_note_rounded,
            ),
          ),
          const SizedBox(height: 20),

          // خواننده با جستجوی live
          _buildSectionTitle('نام خواننده'),
          const SizedBox(height: 10),
          _buildArtistField(),
          const SizedBox(height: 20),

          // تگ‌ها
          _buildSectionTitle('تگ‌ها', optional: true),
          const SizedBox(height: 10),
          _buildTagsField(),
          const SizedBox(height: 20),

          // توضیحات
          _buildSectionTitle('توضیحات', optional: true),
          const SizedBox(height: 10),
          TextField(
            controller: _descController,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: AppColors.darkTextPrimary),
            decoration: _inputDecoration(
              hint: 'درباره این آهنگ بنویس...',
              icon: Icons.notes_rounded,
            ),
          ),
          const SizedBox(height: 20),

          // visibility
          _buildSectionTitle('دسترسی'),
          const SizedBox(height: 10),
          _buildVisibilitySelector(),
          const SizedBox(height: 32),

          // دکمه آپلود
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.cloud_upload_rounded, size: 22),
              label: const Text(
                'افزودن آهنگ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _pickAudioFile,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _audioFilePath != null
                ? AppColors.primary
                : AppColors.darkTextSecondary.withOpacity(0.3),
            width: _audioFilePath != null ? 2 : 1,
          ),
        ),
        child: _audioFilePath == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.audio_file_rounded,
                      color: AppColors.primary, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'برای انتخاب فایل کلیک کنید',
                    style: TextStyle(color: AppColors.darkTextSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'MP3 • WAV • FLAC • AAC • OGG',
                    style: TextStyle(
                        color: AppColors.darkTextSecondary, fontSize: 11),
                  ),
                ],
              )
            : Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.audio_file_rounded,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _audioFileName ?? '',
                          style: const TextStyle(
                            color: AppColors.darkTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'فایل انتخاب شد ✓',
                          style: TextStyle(
                              color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.darkTextSecondary),
                    onPressed: () =>
                        setState(() => _audioFilePath = null),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Column(
      children: [
        TextField(
          controller: _urlController,
          style: const TextStyle(color: AppColors.darkTextPrimary),
          decoration: _inputDecoration(
            hint: 'https://example.com/song.mp3',
            icon: Icons.link_rounded,
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: AppColors.darkTextSecondary, size: 14),
            SizedBox(width: 6),
            Text(
              'فایل به صورت خودکار دانلود و آپلود می‌شود',
              style:
                  TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoverPicker() {
    return GestureDetector(
      onTap: _pickCover,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _coverPath != null
                ? AppColors.primary
                : AppColors.darkTextSecondary.withOpacity(0.3),
          ),
        ),
        child: _coverPath == null
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      color: AppColors.primary, size: 28),
                  SizedBox(width: 10),
                  Text('انتخاب تصویر کاور',
                      style: TextStyle(color: AppColors.darkTextSecondary)),
                ],
              )
            : Row(
                children: [
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_coverPath!),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('کاور انتخاب شد ✓',
                        style: TextStyle(color: Colors.green)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.darkTextSecondary),
                    onPressed: () => setState(() => _coverPath = null),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildArtistField() {
    final query = _artistController.text;
    final suggestionsAsync = _showArtistSuggestions
        ? ref.watch(artistSearchProvider(query))
        : null;

    return Column(
      children: [
        TextField(
          controller: _artistController,
          style: const TextStyle(color: AppColors.darkTextPrimary),
          decoration: _inputDecoration(
            hint: 'نام خواننده را وارد کنید',
            icon: Icons.person_rounded,
          ),
        ),
        if (_showArtistSuggestions &&
            suggestionsAsync != null)
          suggestionsAsync.when(
            data: (users) => users.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: users
                          .map((user) => ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    (user['username'] as String)[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12),
                                  ),
                                ),
                                title: Text(
                                  user['username'] as String,
                                  style: const TextStyle(
                                      color: AppColors.darkTextPrimary,
                                      fontSize: 14),
                                ),
                                onTap: () {
                                  _artistController.text =
                                      user['username'] as String;
                                  setState(
                                      () => _showArtistSuggestions = false);
                                },
                              ))
                          .toList(),
                    ),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildTagsField() {
    final query = _tagInputController.text;
    final suggestionsAsync = _showTagSuggestions
        ? ref.watch(tagSearchProvider(query))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // تگ‌های اضافه شده
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map((tag) => Chip(
                      label: Text(tag,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      backgroundColor: AppColors.primary,
                      deleteIcon: const Icon(Icons.close_rounded,
                          size: 14, color: Colors.white),
                      onDeleted: () => _removeTag(tag),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
        ],

        // input تگ
        TextField(
          controller: _tagInputController,
          style: const TextStyle(color: AppColors.darkTextPrimary),
          decoration: _inputDecoration(
            hint: 'تگ بنویسید و Enter بزنید',
            icon: Icons.tag_rounded,
          ),
          onSubmitted: _addTag,
        ),

        // پیشنهادات تگ
        if (_showTagSuggestions && suggestionsAsync != null)
          suggestionsAsync.when(
            data: (tags) => tags.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags
                          .map((tag) => GestureDetector(
                                onTap: () => _addTag(tag),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurface,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withOpacity(0.5)),
                                  ),
                                  child: Text(tag,
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12)),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildVisibilitySelector() {
    return Row(
      children: [
        _VisibilityOption(
          icon: Icons.public_rounded,
          label: 'عمومی',
          value: 'public',
          selected: _visibility,
          onTap: () => setState(() => _visibility = 'public'),
        ),
        const SizedBox(width: 12),
        _VisibilityOption(
          icon: Icons.lock_outline_rounded,
          label: 'خصوصی',
          value: 'private',
          selected: _visibility,
          onTap: () => setState(() => _visibility = 'private'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool optional = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          const Text(
            '(اختیاری)',
            style:
                TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
      prefixIcon: Icon(icon, color: AppColors.darkTextSecondary, size: 20),
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppColors.darkTextSecondary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      counterStyle:
          const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.darkTextSecondary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.darkTextSecondary,
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.darkTextSecondary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
