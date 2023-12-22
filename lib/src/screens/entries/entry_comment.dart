import 'package:flutter/material.dart';
import 'package:interstellar/src/api/comments.dart' as api_comments;
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/display_name.dart';
import 'package:interstellar/src/widgets/markdown.dart';
import 'package:provider/provider.dart';

class EntryComment extends StatefulWidget {
  const EntryComment(this.comment, this.onUpdate, {super.key});

  final api_comments.Comment comment;
  final void Function(api_comments.Comment) onUpdate;

  @override
  State<EntryComment> createState() => _EntryCommentState();
}

class _EntryCommentState extends State<EntryComment> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 0, 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DisplayName(
                  widget.comment.user.username,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserScreen(
                          widget.comment.user.userId,
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    timeDiffFormat(widget.comment.createdAt),
                    style: const TextStyle(fontWeight: FontWeight.w300),
                  ),
                ),
                const Spacer(),
                if (widget.comment.childCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: IconButton(
                        tooltip: _isCollapsed ? 'Expand' : 'Collapse',
                        onPressed: () => setState(() {
                              _isCollapsed = !_isCollapsed;
                            }),
                        icon: _isCollapsed
                            ? const Icon(Icons.expand_more)
                            : const Icon(Icons.expand_less)),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.rocket_launch),
                  color: widget.comment.userVote == 1
                      ? Colors.purple.shade400
                      : null,
                  onPressed: whenLoggedIn(context, () async {
                    var newValue = await api_comments.putVote(
                      context.read<SettingsController>().httpClient,
                      context.read<SettingsController>().instanceHost,
                      widget.comment.commentId,
                      1,
                    );
                    newValue.childCount = widget.comment.childCount;
                    newValue.children = widget.comment.children;
                    widget.onUpdate(newValue);
                  }),
                ),
                Text(intFormat(widget.comment.uv)),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  color: widget.comment.isFavourited == true
                      ? Colors.green.shade400
                      : null,
                  onPressed: whenLoggedIn(context, () async {
                    var newValue = await api_comments.putFavorite(
                      context.read<SettingsController>().httpClient,
                      context.read<SettingsController>().instanceHost,
                      widget.comment.commentId,
                    );
                    newValue.childCount = widget.comment.childCount;
                    newValue.children = widget.comment.children;
                    widget.onUpdate(newValue);
                  }),
                ),
                Text(intFormat(widget.comment.favourites - widget.comment.dv)),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  color: widget.comment.userVote == -1
                      ? Colors.red.shade400
                      : null,
                  onPressed: whenLoggedIn(context, () async {
                    var newValue = await api_comments.putVote(
                      context.read<SettingsController>().httpClient,
                      context.read<SettingsController>().instanceHost,
                      widget.comment.commentId,
                      -1,
                    );
                    newValue.childCount = widget.comment.childCount;
                    newValue.children = widget.comment.children;
                    widget.onUpdate(newValue);
                  }),
                ),
                const SizedBox(
                  width: 6,
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 12),
              child: Markdown(widget.comment.body),
            ),
            if (!_isCollapsed && widget.comment.childCount > 0)
              Column(
                children: widget.comment.children!
                    .asMap()
                    .entries
                    .map((item) => EntryComment(item.value, (newValue) {
                          var newComment = widget.comment;
                          newComment.children![item.key] = newValue;
                          widget.onUpdate(newComment);
                        }))
                    .toList(),
              )
          ],
        ),
      ),
    );
  }
}
