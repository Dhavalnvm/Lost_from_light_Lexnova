import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common/common_widgets.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _api = ApiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _language = 'English';

  static const List<String> _languages = [
    'English', 'Hindi', 'Marathi', 'Spanish', 'French',
  ];

  static const List<Map<String, dynamic>> _suggestedQuestions = [
    {
      'question': 'What is a non-compete clause?',
      'icon': Icons.work_off_rounded,
    },
    {
      'question': 'What should I check before signing a rental agreement?',
      'icon': Icons.home_rounded,
    },
    {
      'question': 'What are my rights as an employee?',
      'icon': Icons.badge_rounded,
    },
    {
      'question': 'Explain what an NDA is and when it applies',
      'icon': Icons.lock_outline_rounded,
    },
    {
      'question': 'What is the difference between a void and voidable contract?',
      'icon': Icons.gavel_rounded,
    },
    {
      'question': 'What happens if one party breaches a contract?',
      'icon': Icons.warning_amber_rounded,
    },
  ];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final history = _messages
          .take(_messages.length - 1)
          .map((m) => m.toJson())
          .toList();

      final response = await _api.legalChat(text, history, _language);

      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: response.aiResponse,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: 'Sorry, I ran into an error. Please try again.',
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() => _messages.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeScreen()
                : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
            bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.balance_rounded,
                color: AppColors.background, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lex — AI Lawyer',
                  style: AppTextStyles.goldTitle.copyWith(fontSize: 18),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.safeGreen,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(child: Text(
                      'Online · General legal guidance',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
              ],
            ),
          ),
          // Language selector
          GestureDetector(
            onTap: _showLanguagePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.goldGlow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.goldDark.withOpacity(0.5), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded,
                      color: AppColors.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _language,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_messages.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _clearChat,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textMuted, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Select Language',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          ..._languages.map((lang) => ListTile(
            title: Text(lang,
                style: const TextStyle(color: AppColors.textPrimary)),
            trailing: _language == lang
                ? const Icon(Icons.check_circle_rounded,
                color: AppColors.gold)
                : null,
            onTap: () {
              setState(() => _language = lang);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.balance_rounded,
                      color: AppColors.background, size: 38),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(
                    duration: 2000.ms, color: AppColors.goldLight)
                    .animate()
                    .scale(
                    begin: const Offset(0, 0),
                    duration: 600.ms,
                    curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  'Ask Lex Anything',
                  style: AppTextStyles.displayTitle,
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3),
                const SizedBox(height: 8),
                Text(
                  'Your AI legal assistant.\nNot a lawyer, but knows a lot about law.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ).animate(delay: 300.ms).fadeIn(),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text('SUGGESTED QUESTIONS', style: AppTextStyles.sectionTitle)
              .animate(delay: 400.ms)
              .fadeIn(),
          const SizedBox(height: 12),

          ...(_suggestedQuestions.asMap().entries.map((e) {
            final q = e.value;
            return GestureDetector(
              onTap: () => _sendMessage(q['question']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.goldGlow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(q['icon'] as IconData,
                          color: AppColors.gold, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q['question'] as String,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppColors.textMuted, size: 14),
                  ],
                ),
              ),
            )
                .animate(delay: Duration(milliseconds: 400 + e.key * 80))
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.1, end: 0);
          })),

          const SizedBox(height: 20),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.textMuted.withOpacity(0.1), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lex provides general legal education only — not legal advice. '
                        'Always consult a qualified lawyer for your specific situation.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 11, height: 1.5),
                  ),
                ),
              ],
            ),
          ).animate(delay: 900.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length && _isLoading) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[i]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
              ),
              child: const Icon(Icons.balance_rounded,
                  color: AppColors.background, size: 17),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? AppColors.goldGradient
                        : AppColors.cardGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? AppColors.background
                          : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0);
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
            ),
            child: const Icon(Icons.balance_rounded,
                color: AppColors.background, size: 17),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.cardBorder),
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
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                  begin: 0.4,
                  end: 1.2,
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

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask a legal question...',
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                    const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                    const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                        color: AppColors.gold, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 13),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _sendMessage(_controller.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? const LinearGradient(
                      colors: [AppColors.cardBorder, AppColors.cardBorder])
                      : AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading
                      ? []
                      : [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
                    : const Icon(Icons.send_rounded,
                    color: AppColors.background, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}