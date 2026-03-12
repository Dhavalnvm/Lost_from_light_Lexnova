// screens/group_discussion/group_discussion_screen.dart
// -------------------------------------------------------
// Real-time group discussion over a shared PDF document.
// WebSocket-based — messages appear instantly for both participants.
//
// FIXED:
//   • Uses AuthService.currentUser directly (no fake getCurrentUser call)
//   • WS URL built from ApiConfig.wsBase (no fake ApiService.baseUrl)
//   • Removed getToken() call (uses _auth.token directly)
//   • Proper UserProfile field names (userId, name)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

enum _MsgRole { user, partner, ai, system }

class _Msg {
  final _MsgRole role;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String? question;

  _Msg({
    required this.role,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.question,
  });

  factory _Msg.fromHistory(Map<String, dynamic> m, String myUserId) {
    final role = m['role'] == 'ai'
        ? _MsgRole.ai
        : (m['sender_id'] == myUserId ? _MsgRole.user : _MsgRole.partner);
    return _Msg(
      role: role,
      senderName: m['sender_name'] ?? '',
      text: m['content'] ?? '',
      timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

// ─── Lobby (create / join) ────────────────────────────────────────────────────

class GroupDiscussionLobby extends StatefulWidget {
  final String documentId;
  final String documentName;

  const GroupDiscussionLobby({
    super.key,
    required this.documentId,
    required this.documentName,
  });

  @override
  State<GroupDiscussionLobby> createState() => _GroupDiscussionLobbyState();
}

class _GroupDiscussionLobbyState extends State<GroupDiscussionLobby> {
  final _api = ApiService();
  final _auth = AuthService();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  // Pull user info from the in-memory AuthService cache
  String get _userId => _auth.currentUser?.userId ?? '';
  String get _displayName =>
      (_auth.currentUser?.name?.isNotEmpty == true
          ? _auth.currentUser!.name
          : _auth.currentUser?.email) ??
      'You';

  Future<void> _create() async {
    if (_auth.token == null) {
      setState(() => _error = 'Not logged in');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.createGroupRoom(
        documentId: widget.documentId,
        documentName: widget.documentName,
      );
      if (!mounted) return;
      _go(
        roomCode: res['room_code'] as String,
        documentId: widget.documentId,
        documentName: widget.documentName,
      );
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Enter a valid 6-character room code');
      return;
    }
    if (_auth.token == null) {
      setState(() => _error = 'Not logged in');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.joinGroupRoom(roomCode: code);
      if (!mounted) return;
      _go(
        roomCode: code,
        documentId: res['document_id'] as String,
        documentName: res['document_name'] as String? ?? code,
      );
    } catch (e) {
      setState(() { _error = 'Room not found or no longer active'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _go({
    required String roomCode,
    required String documentId,
    required String documentName,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDiscussionScreen(
          roomCode: roomCode,
          documentId: documentId,
          documentName: documentName,
          userId: _userId,
          displayName: _displayName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Group Discussion',
            style: GoogleFonts.cormorantGaramond(
                color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.goldGlow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        color: AppColors.gold, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(widget.documentName,
                          style: GoogleFonts.dmSans(
                              color: AppColors.goldLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 32),

              // Create Room card
              _Card(
                icon: Icons.add_circle_outline_rounded,
                title: 'Start a New Room',
                subtitle: 'Invite your partner with a shareable room code',
                child: _GoldBtn(
                  label: 'Create Room',
                  icon: Icons.rocket_launch_rounded,
                  loading: _loading,
                  onTap: _create,
                ),
              ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 20),

              // Join Room card
              _Card(
                icon: Icons.group_add_rounded,
                title: 'Join Existing Room',
                subtitle: 'Enter the 6-character code from your partner',
                child: Column(
                  children: [
                    TextField(
                      controller: _codeCtrl,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6),
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: 'ABC123',
                        hintStyle: GoogleFonts.dmSans(
                            color: AppColors.textMuted,
                            fontSize: 22,
                            letterSpacing: 6),
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.cardBg,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.cardBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.cardBorder)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.gold, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _GoldBtn(
                      label: 'Join Room',
                      icon: Icons.login_rounded,
                      loading: _loading,
                      onTap: _join,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.15, end: 0),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(_error!,
                              style: GoogleFonts.dmSans(
                                  color: Colors.redAccent, fontSize: 13))),
                    ],
                  ),
                ).animate().fadeIn().shake(),
              ],

              const SizedBox(height: 32),
              _HowItWorks(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chat Screen ──────────────────────────────────────────────────────────────

class GroupDiscussionScreen extends StatefulWidget {
  final String roomCode;
  final String documentId;
  final String documentName;
  final String userId;
  final String displayName;

  const GroupDiscussionScreen({
    super.key,
    required this.roomCode,
    required this.documentId,
    required this.documentName,
    required this.userId,
    required this.displayName,
  });

  @override
  State<GroupDiscussionScreen> createState() => _GroupDiscussionScreenState();
}

class _GroupDiscussionScreenState extends State<GroupDiscussionScreen> {
  late WebSocketChannel _channel;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _aiMode = false;
  bool _aiThinking = false;
  String? _typingUser;
  Timer? _typingTimer;
  bool _connected = false;

  static const _quickAsk = [
    'What is the notice period?',
    'Are there any penalty clauses?',
    'What are the termination conditions?',
    'Who bears the legal costs?',
  ];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    // Build WS URL using ApiConfig.wsBase (correct static getter)
    final wsUrl = ApiConfig.groupChatWs(
        widget.roomCode, widget.userId, widget.displayName);
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    setState(() => _connected = true);
    _channel.stream.listen(
      _onData,
      onError: (_) { if (mounted) setState(() => _connected = false); },
      onDone: ()  { if (mounted) setState(() => _connected = false); },
    );
  }

  void _onData(dynamic raw) {
    if (!mounted) return;
    final data = jsonDecode(raw as String) as Map<String, dynamic>;
    final type = data['type'] as String? ?? '';

    setState(() {
      switch (type) {
        case 'history':
          final list =
              (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _msgs.addAll(list.map((m) => _Msg.fromHistory(m, widget.userId)));
          break;
        case 'message':
          final role = data['role'] == 'user' ? _MsgRole.user : _MsgRole.partner;
          _msgs.add(_Msg(
            role: role,
            senderName: data['sender_name'] ?? '',
            text: data['text'] ?? '',
            timestamp:
                DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
          ));
          _typingUser = null;
          break;
        case 'ai_thinking':
          _aiThinking = true;
          break;
        case 'ai_response':
          _aiThinking = false;
          _msgs.add(_Msg(
            role: _MsgRole.ai,
            senderName: 'Lex',
            text: data['text'] ?? '',
            timestamp:
                DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
            question: data['question'] as String?,
          ));
          break;
        case 'system':
          _msgs.add(_Msg(
            role: _MsgRole.system,
            senderName: 'System',
            text: data['text'] ?? '',
            timestamp:
                DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
          ));
          break;
        case 'typing':
          _typingUser = data['sender_name'] as String?;
          _typingTimer?.cancel();
          _typingTimer = Timer(const Duration(seconds: 3),
              () { if (mounted) setState(() => _typingUser = null); });
          break;
      }
    });
    _scrollToBottom();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || !_connected) return;
    _ctrl.clear();
    _channel.sink.add(
        jsonEncode({'type': _aiMode ? 'ai_query' : 'message', 'text': text}));
  }

  void _onChanged(String _) {
    if (_connected) {
      _channel.sink.add(jsonEncode({'type': 'typing'}));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Room code copied: ${widget.roomCode}',
          style: GoogleFonts.dmSans()),
      backgroundColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    _channel.sink.close();
    _ctrl.dispose();
    _scroll.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!_connected)
            Container(
              color: Colors.red.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Colors.redAccent, size: 14),
                  const SizedBox(width: 6),
                  Text('Disconnected',
                      style: GoogleFonts.dmSans(
                          color: Colors.redAccent, fontSize: 12)),
                ],
              ),
            ),

          Expanded(
            child: _msgs.isEmpty && !_aiThinking
                ? _emptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _msgs.length + (_aiThinking ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _msgs.length) return _AiThinkingBubble();
                      return _bubble(_msgs[i]);
                    },
                  ),
          ),

          if (_typingUser != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('$_typingUser is typing...',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ),
            ),

          if (_aiMode && _msgs.where((m) => m.role == _MsgRole.ai).isEmpty)
            _quickAskRow(),

          _inputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Room: ',
                style: GoogleFonts.dmSans(
                    color: AppColors.textMuted, fontSize: 12)),
            GestureDetector(
              onTap: _copyCode,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.roomCode,
                        style: GoogleFonts.dmSans(
                            color: AppColors.background,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    const SizedBox(width: 4),
                    const Icon(Icons.copy_rounded,
                        color: AppColors.background, size: 12),
                  ],
                ),
              ),
            ),
          ]),
          Text(widget.documentName,
              style:
                  GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _connected
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: (_connected ? Colors.green : Colors.red)
                    .withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _connected
                          ? Colors.greenAccent
                          : Colors.redAccent)),
              const SizedBox(width: 5),
              Text(_connected ? 'Live' : 'Off',
                  style: GoogleFonts.dmSans(
                      color: _connected
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bubble(_Msg msg) {
    if (msg.role == _MsgRole.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(msg.text,
                style: GoogleFonts.dmSans(
                    color: AppColors.textMuted, fontSize: 12)),
          ),
        ),
      ).animate().fadeIn();
    }
    if (msg.role == _MsgRole.ai) return _AiBubble(msg: msg);

    final isMe = msg.role == _MsgRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _Avatar(name: msg.senderName, color: const Color(0xFF6B9FD4)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(msg.senderName,
                        style: GoogleFonts.dmSans(
                            color: const Color(0xFF6B9FD4),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppColors.goldGradient : null,
                    color: isMe ? null : AppColors.cardBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(msg.text,
                      style: GoogleFonts.dmSans(
                          color: isMe
                              ? AppColors.background
                              : AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5)),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.12, end: 0);
  }

  Widget _quickAskRow() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickAsk.length,
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () {
            _ctrl.text = _quickAsk[i];
            _send();
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.goldGlow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.goldDark.withOpacity(0.5)),
            ),
            child: Text(_quickAsk[i],
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Toggle(
                label: 'Chat',
                icon: Icons.chat_bubble_outline_rounded,
                active: !_aiMode,
                onTap: () => setState(() => _aiMode = false),
              ),
              const SizedBox(width: 8),
              _Toggle(
                label: 'Ask Lex',
                icon: Icons.auto_awesome_rounded,
                active: _aiMode,
                onTap: () => setState(() => _aiMode = true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 14),
                  maxLines: 3,
                  minLines: 1,
                  onChanged: _onChanged,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: _aiMode
                        ? 'Ask Lex about this document...'
                        : 'Message your partner...',
                    hintStyle: GoogleFonts.dmSans(
                        color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: _aiMode
                                ? AppColors.gold
                                : const Color(0xFF6B9FD4),
                            width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _aiMode
                        ? AppColors.goldGradient
                        : const LinearGradient(
                            colors: [Color(0xFF4A8BC4), Color(0xFF6B9FD4)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: (_aiMode
                                  ? AppColors.gold
                                  : const Color(0xFF4A8BC4))
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Icon(
                    _aiMode
                        ? Icons.auto_awesome_rounded
                        : Icons.send_rounded,
                    color: AppColors.background,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
              boxShadow: [
                BoxShadow(
                    color: AppColors.gold.withOpacity(0.3), blurRadius: 24)
              ],
            ),
            child: const Icon(Icons.groups_rounded,
                color: AppColors.background, size: 38),
          ),
          const SizedBox(height: 20),
          Text('Room Active',
              style: GoogleFonts.cormorantGaramond(
                  color: AppColors.gold,
                  fontSize: 22,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Share the room code with your partner\nto start discussing this document.',
            style: GoogleFonts.dmSans(
                color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _copyCode,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.roomCode,
                      style: GoogleFonts.dmSans(
                          color: AppColors.background,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4)),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded,
                      color: AppColors.background, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Tap to copy',
              style: GoogleFonts.dmSans(
                  color: AppColors.textMuted, fontSize: 11)),
        ],
      ).animate().fadeIn(),
    );
  }
}

// ─── AI bubbles ───────────────────────────────────────────────────────────────

class _AiBubble extends StatelessWidget {
  final _Msg msg;
  const _AiBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, gradient: AppColors.goldGradient),
            child: const Icon(Icons.balance_rounded,
                color: AppColors.background, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Lex',
                        style: GoogleFonts.dmSans(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    if (msg.question != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '· asked by ${msg.senderName}',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textMuted, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (msg.question != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.goldGlow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.gold.withOpacity(0.2)),
                    ),
                    child: Text('"${msg.question}"',
                        style: GoogleFonts.dmSans(
                            color: AppColors.goldLight,
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                  ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                        color: AppColors.gold.withOpacity(0.25), width: 1),
                  ),
                  child: Text(msg.text,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.55)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _AiThinkingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, gradient: AppColors.goldGradient),
            child: const Icon(Icons.balance_rounded,
                color: AppColors.background, size: 18),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.gold),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                      begin: 0.5,
                      end: 1.3,
                      duration: 500.ms,
                      delay: Duration(milliseconds: i * 160),
                      curve: Curves.easeInOut,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  const _Avatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.dmSans(
              color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _Toggle(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? AppColors.goldGradient : null,
          color: active ? null : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppColors.gold : AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? AppColors.background : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.background : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _GoldBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;
  const _GoldBtn(
      {required this.label,
      required this.icon,
      required this.loading,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.gold.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.background, strokeWidth: 2)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.background, size: 18),
                  const SizedBox(width: 10),
                  Text(label,
                      style: GoogleFonts.dmSans(
                          color: AppColors.background,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  const _Card(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.goldGlow,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.gold, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: GoogleFonts.dmSans(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  static const _steps = [
    (Icons.upload_file_rounded, 'Upload a PDF',
        'Make sure the document is uploaded first'),
    (Icons.add_circle_outline_rounded, 'Create a Room',
        'A unique 6-character code is generated'),
    (Icons.share_rounded, 'Share the Code',
        'Send it via any messaging app'),
    (Icons.chat_rounded, 'Discuss Together',
        'Both of you can chat and ask Lex questions live'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How it works',
            style: GoogleFonts.cormorantGaramond(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._steps.asMap().entries.map((e) {
          final i = e.key;
          final (icon, title, desc) = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: AppColors.goldGlow,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.gold.withOpacity(0.3))),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.dmSans(
                            color: AppColors.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(desc,
                          style: GoogleFonts.dmSans(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 280 + i * 80));
        }),
      ],
    );
  }
}