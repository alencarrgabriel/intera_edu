import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/di/service_locator.dart';

/// Campo de texto com autocompletar de @menções acadêmicas.
///
/// Detecta `@xxx` ao digitar e chama `/users/search?q=` debounceado.
/// Quando o usuário toca numa sugestão, substitui o token pelo `@handle`.
class MentionAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final TextAlignVertical? textAlignVertical;
  final ValueChanged<String>? onChanged;

  const MentionAutocompleteField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.textAlignVertical,
    this.onChanged,
  });

  @override
  State<MentionAutocompleteField> createState() =>
      _MentionAutocompleteFieldState();
}

class _MentionAutocompleteFieldState extends State<MentionAutocompleteField> {
  Timer? _debounce;
  OverlayEntry? _overlay;
  List<Map<String, dynamic>> _suggestions = const [];
  final LayerLink _link = LayerLink();
  String _currentPrefix = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final caret = selection.baseOffset;
    if (caret <= 0) {
      _removeOverlay();
      return;
    }
    // Encontra o último @ até o caret
    final before = text.substring(0, caret);
    final atIdx = before.lastIndexOf('@');
    if (atIdx < 0) {
      _removeOverlay();
      return;
    }
    // Token só vale se a posição anterior é início ou espaço
    if (atIdx > 0) {
      final prev = before[atIdx - 1];
      if (prev != ' ' && prev != '\n') {
        _removeOverlay();
        return;
      }
    }
    final token = before.substring(atIdx + 1);
    if (token.contains(' ') || token.length > 32) {
      _removeOverlay();
      return;
    }
    _currentPrefix = token;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () => _search(token));
  }

  Future<void> _search(String prefix) async {
    if (prefix.isEmpty) {
      _suggestions = const [];
      _refreshOverlay();
      return;
    }
    try {
      final res = await sl.profileRepo.searchUsersByHandlePrefix(prefix);
      if (!mounted) return;
      _suggestions = res.take(5).toList();
      _refreshOverlay();
    } catch (_) {
      _suggestions = const [];
      _refreshOverlay();
    }
  }

  void _refreshOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty) return;
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Widget _buildOverlay(BuildContext ctx) {
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 240;
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        offset: Offset(0, (box?.size.height ?? 56) + 4),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          color: AppTokens.surfaceContainerLowest,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _suggestions
                .map(
                  (u) => InkWell(
                    onTap: () => _pick(u),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: u['avatar_url'] != null
                                ? NetworkImage(u['avatar_url'] as String)
                                : null,
                            backgroundColor: AppTokens.primaryContainer,
                            child: u['avatar_url'] == null
                                ? Text(
                                    ((u['full_name'] ?? '?') as String)
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                        color: AppTokens.onPrimaryContainer,
                                        fontSize: 12),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (u['full_name'] ?? '—') as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (u['handle'] != null)
                                  Text(
                                    '@${u['handle']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTokens.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _pick(Map<String, dynamic> user) {
    final handle = (user['handle'] ?? '') as String;
    if (handle.isEmpty) {
      _removeOverlay();
      return;
    }
    final text = widget.controller.text;
    final caret = widget.controller.selection.baseOffset;
    final before = text.substring(0, caret);
    final atIdx = before.lastIndexOf('@');
    if (atIdx < 0) {
      _removeOverlay();
      return;
    }
    final after = text.substring(caret);
    final replaced = '${text.substring(0, atIdx)}@$handle $after';
    widget.controller.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(offset: atIdx + handle.length + 2),
    );
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        decoration: widget.decoration,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        expands: widget.expands,
        maxLength: widget.maxLength,
        textAlignVertical: widget.textAlignVertical,
        onChanged: widget.onChanged,
      ),
    );
  }
}
