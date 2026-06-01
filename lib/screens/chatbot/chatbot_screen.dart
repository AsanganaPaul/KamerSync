import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _uuid = const Uuid();
  List<ChatMessage> _messages = [];
  bool _isSending = false;
  late GenerativeModel? _model;
  late ChatSession? _chat;

  static const String _systemContext = '''
You are a helpful assistant for the KamerSync — Cameroon National Land Management System (NLMS).
You help citizens, officers, surveyors, and other stakeholders with:
- Land registration process and requirements
- Required documents (title deeds, survey plans, national IDs, tax receipts)
- Land verification and ownership lookup
- Application status tracking
- MINDCAF office locations and contact information
- Transfer of land ownership procedures
- GIS and boundary marking guidance
- Blockchain transaction verification
- General land law and regulations in Cameroon
Always be professional, helpful, and provide accurate information. 
If you don't know something, advise the user to contact the nearest MINDCAF office.
''';

  @override
  void initState() {
    super.initState();
    _initGemini();
    _addWelcomeMessage();
  }

  void _initGemini() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isNotEmpty && apiKey != 'your_gemini_api_key_here') {
        _model = GenerativeModel(
          model: 'gemini-1.5-pro',
          apiKey: apiKey,
          systemInstruction: Content.system(_systemContext),
        );
        _chat = _model!.startChat();
      } else {
        _model = null;
        _chat = null;
      }
    } catch (e) {
      _model = null;
      _chat = null;
    }
  }

  void _addWelcomeMessage() {
    _messages = [
      ChatMessage(
        id: _uuid.v4(),
        content:
            "Hello! I'm KamerBot 🌿, your AI assistant for the Cameroon National Land Management System.\n\n"
            "I can help you with:\n"
            "• 📋 Land registration process\n"
            "• 📄 Required documents\n"
            "• 🔍 How to verify land ownership\n"
            "• 📍 MINDCAF office information\n"
            "• ⚖️ Land transfer procedures\n\n"
            "How can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final loadingMsg = ChatMessage(
      id: _uuid.v4(),
      content: '...',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(loadingMsg);
      _isSending = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    try {
      String responseText;

      if (_chat != null) {
        // Real Gemini API call
        final response = await _chat!.sendMessage(Content.text(text));
        responseText = response.text ?? 'I could not generate a response.';
      } else {
        // Demo mode — simulated responses
        await Future.delayed(const Duration(seconds: 1, milliseconds: 200));
        responseText = _getDemoResponse(text);
      }

      final botMsg = ChatMessage(
        id: _uuid.v4(),
        content: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.removeLast(); // remove loading
        _messages.add(botMsg);
        _isSending = false;
      });
    } catch (e) {
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        content:
            'Sorry, I encountered an error: ${e.toString().replaceAll('Exception: ', '')}. '
            'Please try again or contact MINDCAF directly.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.removeLast();
        _messages.add(errorMsg);
        _isSending = false;
      });
    }

    _scrollToBottom();
  }

  String _getDemoResponse(String query) {
    final q = query.toLowerCase();

    if (q.contains('register') || q.contains('registration')) {
      return '📋 **Land Registration Process in Cameroon:**\n\n'
          '1. **Prepare Documents**: Gather your national ID, tax receipts, and any existing property documents.\n'
          '2. **Submit Application**: Use KamerSync app or visit MINDCAF office.\n'
          '3. **Boundary Survey**: A certified surveyor will visit and mark boundaries.\n'
          '4. **MINDCAF Review**: Officers review your application (7-30 days).\n'
          '5. **Title Issuance**: Upon approval, a unique Land ID is issued.\n\n'
          '💡 *Required documents: National ID, tax receipt, plot plan, witness statements.*';
    } else if (q.contains('document') || q.contains('required')) {
      return '📄 **Required Documents for Land Registration:**\n\n'
          '• ✅ Certified copy of National ID Card\n'
          '• ✅ Official survey plan (from certified surveyor)\n'
          '• ✅ Tax clearance certificate\n'
          '• ✅ Title deed (if existing)\n'
          '• ✅ 2 witness statements\n'
          '• ✅ Payment receipts\n\n'
          'All documents must be originals or certified copies. PDFs and high-quality scans are accepted in the app.';
    } else if (q.contains('verif')) {
      return '🔍 **How to Verify Land Ownership:**\n\n'
          '**Via KamerSync App:**\n'
          '1. Go to "Verify Land" from dashboard\n'
          '2. Enter the Land ID (e.g., CM-CTR-2024-0001) or owner name\n'
          '3. View instant ownership details and blockchain confirmation\n\n'
          '**MINDCAF Offices:**\n'
          '• Yaoundé Central: Avenue Kennedy, Tel: +237 222 23 45 00\n'
          '• Douala: Rue de la Liberté, Tel: +237 233 40 23 10\n'
          '• Open: Mon-Fri, 8am-3pm';
    } else if (q.contains('transfer') || q.contains('ownership')) {
      return '🔄 **Land Ownership Transfer Process:**\n\n'
          '1. Current owner initiates transfer in KamerSync app\n'
          '2. Enter new owner details (name, email, phone)\n'
          '3. Both parties sign notarized agreement\n'
          '4. Submit to MINDCAF for approval\n'
          '5. Blockchain record created upon completion\n\n'
          '⚠️ *Transfer requires notary presence and MINDCAF approval. Fees apply.*';
    } else if (q.contains('fee') || q.contains('cost') || q.contains('price')) {
      return '💰 **Land Registration Fees (Approximate):**\n\n'
          '• Application fee: 25,000 XAF\n'
          '• Survey fee: 50,000 – 200,000 XAF (varies by area)\n'
          '• Title deed issuance: 15,000 XAF\n'
          '• Transfer fees: 2% of property value + 10,000 XAF\n\n'
          '*Fees are subject to change. Contact MINDCAF for current rates.*';
    } else if (q.contains('status') || q.contains('track')) {
      return '📊 **Application Status Tracking:**\n\n'
          '**Status Stages:**\n'
          '• 🟡 **Pending** — Application submitted, awaiting review\n'
          '• 🔵 **Under Review** — Being processed by MINDCAF\n'
          '• 🟢 **Approved** — Land ID issued, title ready\n'
          '• 🔴 **Rejected** — See rejection reason, resubmit if needed\n\n'
          'You\'ll receive push notifications for every status change!';
    } else if (q.contains('blockchain') || q.contains('hash')) {
      return '🔗 **Blockchain Land Records:**\n\n'
          'KamerSync uses SHA-256 blockchain technology to:\n'
          '• Create immutable records of every land transaction\n'
          '• Prevent fraudulent ownership claims\n'
          '• Provide tamper-proof audit trails\n'
          '• Enable instant verification by any stakeholder\n\n'
          'Every approved registration and transfer generates a unique transaction hash stored in the distributed ledger.';
    } else if (q.contains('hello') || q.contains('hi') || q.contains('help')) {
      return '👋 Hello! I\'m here to help you with the Cameroon National Land Management System.\n\n'
          'Ask me about:\n'
          '• Land registration requirements\n'
          '• Document checklist\n'
          '• How to verify ownership\n'
          '• Transfer procedures\n'
          '• Office locations\n'
          '• Application fees\n\n'
          'What would you like to know?';
    } else {
      return 'Thank you for your question about "${query}".\n\n'
          'For detailed information, I recommend:\n'
          '1. Visiting the nearest MINDCAF office\n'
          '2. Calling: +237 222 22 30 00 (National hotline)\n'
          '3. Email: info@mindcaf.gov.cm\n\n'
          'Is there anything specific about land registration, verification, or documents I can help with?';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KamerBot AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(
                  _chat != null ? 'Gemini 1.5 Pro' : 'Demo Mode',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // API key warning
          if (_chat == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.accent.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Running in demo mode. Add GEMINI_API_KEY to .env for full AI responses.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return _MessageBubble(message: msg);
              },
            ),
          ),

          // Quick suggestions
          if (_messages.length <= 2)
            _buildSuggestions(),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      'How do I register land?',
      'What documents do I need?',
      'How to verify ownership?',
      'What are the fees?',
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(suggestions[i], style: const TextStyle(fontSize: 12)),
              onPressed: () {
                _msgCtrl.text = suggestions[i];
                _sendMessage();
              },
              backgroundColor: AppColors.surfaceVariant,
              side: const BorderSide(color: AppColors.border),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Ask about land registration...',
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      iconSize: 20,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.divider),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: message.isLoading
                  ? _TypingIndicator()
                  : Text(
                      message.content,
                      style: TextStyle(
                        color:
                            isUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.person_outline,
                  size: 16, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final bounce = ((_controller.value * 3 - i) % 1).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8 + (bounce < 0.5 ? bounce * 4 : (1 - bounce) * 4),
              decoration: BoxDecoration(
                color: AppColors.textHint,
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      ),
    );
  }
}
