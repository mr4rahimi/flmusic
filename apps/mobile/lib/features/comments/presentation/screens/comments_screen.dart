import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/comments_provider.dart';
import '../../data/comment_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  final String trackId;
  final String trackTitle;
  final int commentsCount;

  const CommentsScreen({
    super.key,
    required this.trackId,
    required this.trackTitle,
    required this.commentsCount,
  });

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final success = await ref
        .read(commentsProvider(widget.trackId).notifier)
        .addComment(text);

    if (success) {
      _controller.clear();
      _focusNode.unfocus();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در ارسال کامنت'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.trackId));
    final authUser = ref.watch(authStateProvider).value;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85 - 
          MediaQuery.of(context).viewInsets.bottom,
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkTextSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.comment_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'کامنت‌ها',
                    style: const TextStyle(
                      color: AppColors.darkTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                commentsAsync.when(
                  data: (comments) => Text(
                    '${comments.length}',
                    style: const TextStyle(
                        color: AppColors.darkTextSecondary, fontSize: 14),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.darkCard, height: 1),

          // Comments List
          Expanded(
            child: commentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('خطا در بارگذاری',
                        style:
                            TextStyle(color: AppColors.darkTextSecondary)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref
                          .read(commentsProvider(widget.trackId)
                              .notifier)
                          .loadComments(),
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              ),
              data: (comments) => comments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: AppColors.darkTextSecondary, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'اولین کامنت رو بذار!',
                            style: TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (_, i) => _CommentItem(
                        comment: comments[i],
                        isOwner:
                            authUser?.id == comments[i].user.id,
                        onDelete: () => ref
                            .read(commentsProvider(widget.trackId)
                                .notifier)
                            .deleteComment(comments[i].id),
                        onUserTap: () {
                          Navigator.pop(context);
                          context.push(
                              '/profile/${comments[i].user.username}');
                        },
                      ),
                    ),
            ),
          ),

          // Input
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              border: Border(
                  top: BorderSide(
                      color: AppColors.darkTextSecondary.withOpacity(0.2))),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    authUser?.username[0].toUpperCase() ?? '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),

                // Input field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 500,
                    style: const TextStyle(
                        color: AppColors.darkTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'کامنت بنویس...',
                      hintStyle: const TextStyle(
                          color: AppColors.darkTextSecondary, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.darkSurface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: _sending ? null : _submit,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _sending
                          ? AppColors.darkTextSecondary
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  final bool isOwner;
  final VoidCallback onDelete;
  final VoidCallback onUserTap;

  const _CommentItem({
    required this.comment,
    required this.isOwner,
    required this.onDelete,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        GestureDetector(
          onTap: onUserTap,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              comment.user.username[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onUserTap,
                    child: Text(
                      comment.user.username,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeago.format(comment.createdAt, locale: 'fa'),
                    style: const TextStyle(
                        color: AppColors.darkTextSecondary, fontSize: 11),
                  ),
                  if (isOwner) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showDeleteDialog(context),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.darkTextSecondary, size: 16),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  comment.content,
                  style: const TextStyle(
                      color: AppColors.darkTextPrimary, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('حذف کامنت',
            style: TextStyle(color: AppColors.darkTextPrimary)),
        content: const Text('مطمئنی؟',
            style: TextStyle(color: AppColors.darkTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف',
                style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: const Text('حذف',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
