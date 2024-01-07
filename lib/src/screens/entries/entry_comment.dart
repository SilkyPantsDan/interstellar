import 'package:flutter/material.dart';
import 'package:interstellar/src/api/comments.dart' as api_comments;
import 'package:interstellar/src/models/entry_comment.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/content_item.dart';
import 'package:provider/provider.dart';

class EntryComment extends StatefulWidget {
  const EntryComment(this.comment, this.onUpdate, {super.key});

  final EntryCommentModel comment;
  final void Function(EntryCommentModel) onUpdate;

  @override
  State<EntryComment> createState() => _EntryCommentState();
}

class _EntryCommentState extends State<EntryComment> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ContentItem(
        body: widget.comment.body ?? '_comment deleted_',
        createdAt: widget.comment.createdAt,
        user: widget.comment.user.username,
        userIcon: widget.comment.user.avatar?.storageUrl,
        userIdOnClick: widget.comment.user.userId,
        boosts: widget.comment.uv,
        isBoosted: widget.comment.userVote == 1,
        onBoost: whenLoggedIn(context, () async {
          var newValue = await api_comments.putVote(
            context.read<SettingsController>().httpClient,
            context.read<SettingsController>().instanceHost,
            widget.comment.commentId,
            1,
          );
          widget.onUpdate(newValue.copyWith(
            childCount: widget.comment.childCount,
            children: widget.comment.children,
          ));
        }),
        upVotes: widget.comment.favourites,
        isUpVoted: widget.comment.isFavourited == true,
        onUpVote: whenLoggedIn(context, () async {
          var newValue = await api_comments.putFavorite(
            context.read<SettingsController>().httpClient,
            context.read<SettingsController>().instanceHost,
            widget.comment.commentId,
          );
          widget.onUpdate(newValue.copyWith(
            childCount: widget.comment.childCount,
            children: widget.comment.children,
          ));
        }),
        downVotes: widget.comment.dv,
        isDownVoted: widget.comment.userVote == -1,
        onDownVote: whenLoggedIn(context, () async {
          var newValue = await api_comments.putVote(
            context.read<SettingsController>().httpClient,
            context.read<SettingsController>().instanceHost,
            widget.comment.commentId,
            -1,
          );
          widget.onUpdate(newValue.copyWith(
            childCount: widget.comment.childCount,
            children: widget.comment.children,
          ));
        }),
        showCollapse: true,
        onReply: (body) async {
          var newSubComment = await api_comments.postComment(
            context.read<SettingsController>().httpClient,
            context.read<SettingsController>().instanceHost,
            body,
            widget.comment.entryId,
            parentCommentId: widget.comment.commentId,
          );

          widget.onUpdate(widget.comment.copyWith(
            childCount: widget.comment.childCount + 1,
            children: [newSubComment, ...widget.comment.children!],
          ));
        },
        onEdit: widget.comment.visibility != 'soft_deleted'
            ? whenLoggedIn(context, (body) async {
                var newValue = await api_comments.editComment(
                    context.read<SettingsController>().httpClient,
                    context.read<SettingsController>().instanceHost,
                    widget.comment.commentId,
                    body,
                    widget.comment.lang,
                    widget.comment.isAdult);
                widget.onUpdate(newValue.copyWith(
                  childCount: widget.comment.childCount,
                  children: widget.comment.children,
                ));
              }, matchesUsername: widget.comment.user.username)
            : null,
        onDelete: widget.comment.visibility != 'soft_deleted'
            ? whenLoggedIn(context, () async {
                await api_comments.deleteComment(
                  context.read<SettingsController>().httpClient,
                  context.read<SettingsController>().instanceHost,
                  widget.comment.commentId,
                );
                widget.onUpdate(widget.comment.copyWith(
                  body: '_comment deleted_',
                  uv: null,
                  dv: null,
                  favourites: null,
                  visibility: 'soft_deleted',
                ));
              }, matchesUsername: widget.comment.user.username)
            : null,
        child: widget.comment.childCount > 0
            ? Column(
                children: widget.comment.children!
                    .asMap()
                    .entries
                    .map((item) => EntryComment(item.value, (newValue) {
                          widget.onUpdate(widget.comment.copyWith(
                            childCount: widget.comment.childCount + 1,
                            children: [newValue, ...widget.comment.children!],
                          ));
                        }))
                    .toList(),
              )
            : null,
      ),
    );
  }
}
