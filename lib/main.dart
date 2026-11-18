import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HisabooApp());
}

// -------------------- THEME --------------------

const Color brightBlue = Color(0xFF1677FF);
const Color navyBlue = Color(0xFF0B1B3A);
const Color darkBlack = Color(0xFF05070D);
const Color cardColor = Color(0xFF142744);
const Color lightText = Color(0xFFEAF2FF);

const String storageKey = 'hisaboo_expenses';
const String loginKey = 'hisaboo_logged_in';
const String nameKey = 'hisaboo_user_name';
const String emailKey = 'hisaboo_user_email';
const String passwordKey = 'hisaboo_user_password';

final currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

final List<String> categories = [
  'Food',
  'Travel',
  'Shopping',
  'Education',
  'Bills',
  'Health',
  'Entertainment',
  'Other',
];

final Map<String, String> emojis = {
  'Food': '🍕',
  'Travel': '✈️',
  'Shopping': '🛍️',
  'Education': '📚',
  'Bills': '🧾',
  'Health': '💊',
  'Entertainment': '🎬',
  'Other': '✨',
};

// -------------------- DATA MODEL --------------------

class Expense {
  String title;
  double amount;
  String category;
  DateTime date;
  String type;
  String paymentMethod;
  String notes;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.type = 'Expense',
    this.paymentMethod = 'Cash',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'type': type,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      title: map['title']?.toString() ?? 'Untitled',
      amount: (map['amount'] as num).toDouble(),
      category: map['category']?.toString() ?? 'Other',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      type: map['type']?.toString() ?? 'Expense',
      paymentMethod: map['paymentMethod']?.toString() ?? 'Cash',
      notes: map['notes']?.toString() ?? '',
    );
  }
}

// -------------------- APP --------------------

class HisabooApp extends StatelessWidget {
  const HisabooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HisaBoo',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBlack,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brightBlue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: brightBlue),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// -------------------- LOGIN CHECK --------------------

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> loginStatus;

  @override
  void initState() {
    super.initState();
    loginStatus = checkLogin();
  }

  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(loginKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: loginStatus,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: brightBlue),
            ),
          );
        }

        return snapshot.data! ? const DashboardPage() : const LoginPage();
      },
    );
  }
}

// -------------------- LOGIN / SIGNUP --------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isSignup = false;
  bool hidePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (isSignup) {
      await prefs.setString(nameKey, nameController.text.trim());
      await prefs.setString(emailKey, email);
      await prefs.setString(passwordKey, password);
      await prefs.setBool(loginKey, true);
    } else {
      final savedEmail = prefs.getString(emailKey);
      final savedPassword = prefs.getString(passwordKey);

      if (savedEmail == null) {
        setState(() => isLoading = false);
        showMessage('Please create an account first.');
        return;
      }

      if (email != savedEmail || password != savedPassword) {
        setState(() => isLoading = false);
        showMessage('Incorrect email or password.');
        return;
      }

      await prefs.setBool(loginKey, true);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardPage(),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Container(
                    height: 85,
                    width: 85,
                    decoration: BoxDecoration(
                      color: brightBlue,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'HISABOO',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your money, your control 💙',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 35),
                  Text(
                    isSignup ? 'Create Account ✨' : 'Welcome Back 👋',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (isSignup) ...[
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (isSignup &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                  ],
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null ||
                          !value.contains('@') ||
                          !value.contains('.')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => hidePassword = !hidePassword);
                        },
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 53,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brightBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isLoading ? null : submitForm,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              isSignup ? 'Create Account' : 'Login',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSignup = !isSignup;
                        formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      isSignup
                          ? 'Already have an account? Login'
                          : 'New here? Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- DASHBOARD --------------------

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Expense> entries = [];
  bool isLoading = true;

  String selectedFilter = 'All';
  String searchText = '';
  int selectedPage = 0;
  String userName = 'User';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(storageKey);

    if (savedData != null) {
      try {
        final List decoded = jsonDecode(savedData);
        entries = decoded.map((item) {
          return Expense.fromMap(Map<String, dynamic>.from(item));
        }).toList();
      } catch (_) {
        entries = [];
      }
    }

    userName = prefs.getString(nameKey) ?? 'User';
    userEmail = prefs.getString(emailKey) ?? '';

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = entries.map((e) => e.toMap()).toList();
    await prefs.setString(storageKey, jsonEncode(data));
  }

  double get totalIncome {
    return entries
        .where((e) => e.type == 'Income')
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get totalExpenses {
    return entries
        .where((e) => e.type == 'Expense')
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get balance => totalIncome - totalExpenses;

  double get todayExpenses {
    final now = DateTime.now();

    return entries
        .where((e) =>
            e.type == 'Expense' &&
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get monthlyIncome {
    final now = DateTime.now();

    return entries
        .where((e) =>
            e.type == 'Income' &&
            e.date.year == now.year &&
            e.date.month == now.month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get monthlyExpenses {
    final now = DateTime.now();

    return entries
        .where((e) =>
            e.type == 'Expense' &&
            e.date.year == now.year &&
            e.date.month == now.month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  List<Expense> get filteredEntries {
    return entries.where((entry) {
      final matchesType = selectedFilter == 'All' ||
          (selectedFilter == 'Income' && entry.type == 'Income') ||
          (selectedFilter == 'Expense' && entry.type == 'Expense') ||
          entry.category == selectedFilter;

      final matchesSearch =
          entry.title.toLowerCase().contains(searchText.toLowerCase());

      return matchesType && matchesSearch;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> openEntryForm({Expense? existing}) async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: navyBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => EntryFormSheet(existing: existing),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (existing == null) {
        entries.add(result);
      } else {
        final index = entries.indexOf(existing);
        if (index != -1) entries[index] = result;
      }
    });

    await saveData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null ? 'Entry saved successfully ✓' : 'Entry updated ✓',
        ),
        backgroundColor: brightBlue,
      ),
    );
  }

  Future<void> deleteEntry(Expense entry) async {
    setState(() => entries.remove(entry));
    await saveData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry deleted successfully 🗑️')),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(loginKey, false);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget summaryCard(String title, String amount, IconData icon, String emoji) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: brightBlue.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: brightBlue),
                Text(emoji, style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 13),
            Text(title, style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                amount,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [brightBlue, navyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: brightBlue.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AVAILABLE BALANCE',
            style: TextStyle(color: Colors.white70, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              currency.format(balance),
              key: ValueKey(balance),
              style: const TextStyle(
                fontSize: 33,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text('Your money, your control 💙'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text('Income: ${currency.format(totalIncome)}'),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.trending_down, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text('Expenses: ${currency.format(totalExpenses)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget categoryBreakdown() {
    final Map<String, double> totals = {};

    for (final entry in entries.where((e) => e.type == 'Expense')) {
      totals[entry.category] = (totals[entry.category] ?? 0) + entry.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Expense Breakdown',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          ...sorted.map((item) {
            final percentage =
                totalExpenses == 0 ? 0.0 : item.value / totalExpenses;

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(emojis[item.key] ?? '✨'),
                      const SizedBox(width: 9),
                      Expanded(child: Text(item.key)),
                      Text(
                        currency.format(item.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 7,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(brightBlue),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget entryTile(Expense entry) {
    final isIncome = entry.type == 'Income';

    return Dismissible(
      key: ObjectKey(entry),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => deleteEntry(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 47,
              width: 47,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: brightBlue.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                isIncome ? '💰' : (emojis[entry.category] ?? '✨'),
                style: const TextStyle(fontSize: 23),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${entry.type} • ${entry.category}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(entry.date),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${currency.format(entry.amount)}',
                  style: TextStyle(
                    color: isIncome ? Colors.lightBlueAccent : lightText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () => openEntryForm(existing: entry),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: brightBlue,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => deleteEntry(entry),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget overviewPage() {
    final visible = filteredEntries;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 47,
                width: 47,
                decoration: BoxDecoration(
                  color: brightBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HISABOO',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Hello, $userName 👋',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                backgroundColor: cardColor,
                child: Text('😊'),
              ),
            ],
          ),
          const SizedBox(height: 25),
          balanceCard(),
          const SizedBox(height: 24),
          const Text(
            'Your Overview ✨',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              summaryCard(
                'Total Income',
                currency.format(totalIncome),
                Icons.trending_up,
                '💰',
              ),
              const SizedBox(width: 12),
              summaryCard(
                'Total Expense',
                currency.format(totalExpenses),
                Icons.trending_down,
                '💸',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              summaryCard(
                'Today',
                currency.format(todayExpenses),
                Icons.today,
                '☀️',
              ),
              const SizedBox(width: 12),
              summaryCard(
                'Entries',
                '${entries.length}',
                Icons.receipt_long,
                '🧾',
              ),
            ],
          ),
          const SizedBox(height: 25),
          categoryBreakdown(),
          const SizedBox(height: 24),
          const Text(
            'Recent Transactions 🛍️',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 13),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: Icon(Icons.search, color: brightBlue),
            ),
            onChanged: (value) {
              setState(() => searchText = value);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'All',
                'Income',
                'Expense',
                ...categories,
              ].map((filter) {
                final selected = selectedFilter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => selectedFilter = filter);
                    },
                    selectedColor: brightBlue,
                    backgroundColor: cardColor,
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 15),
          if (visible.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Text('🪄', style: TextStyle(fontSize: 42)),
                  SizedBox(height: 10),
                  Text(
                    'No transactions found!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Add income or expense to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          else
            ...visible.map(entryTile),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Made with 💙 for smarter savings',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget reportsPage() {
    final now = DateTime.now();

    final monthEntries = entries
        .where((e) => e.date.year == now.year && e.date.month == now.month);

    final monthList = monthEntries.toList();

    final highest = monthList.isEmpty
        ? null
        : monthList.reduce((a, b) => a.amount > b.amount ? a : b);

    final expenseCount = monthList.where((e) => e.type == 'Expense').length;

    final average = expenseCount == 0 ? 0.0 : monthlyExpenses / expenseCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Reports 📊',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 23),
          reportCard(
            'Monthly Income',
            currency.format(monthlyIncome),
            Icons.trending_up,
            Colors.lightBlueAccent,
          ),
          const SizedBox(height: 12),
          reportCard(
            'Monthly Expenses',
            currency.format(monthlyExpenses),
            Icons.trending_down,
            Colors.orangeAccent,
          ),
          const SizedBox(height: 12),
          reportCard(
            'Monthly Savings',
            currency.format(monthlyIncome - monthlyExpenses),
            Icons.savings_outlined,
            brightBlue,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Insights ✨',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                insightRow(
                  'Highest transaction',
                  highest == null
                      ? 'No records'
                      : '${highest.title} (${currency.format(highest.amount)})',
                ),
                const Divider(height: 25, color: Colors.white12),
                insightRow(
                  'Average expense',
                  currency.format(average),
                ),
                const Divider(height: 25, color: Colors.white12),
                insightRow(
                  'Total transactions',
                  '${monthList.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          categoryBreakdown(),
        ],
      ),
    );
  }

  Widget reportCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Flexible(
            child: FittedBox(
              child: Text(
                amount,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget insightRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white60),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget profilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SizedBox(height: 25),
          const CircleAvatar(
            radius: 48,
            backgroundColor: brightBlue,
            child: Text('😊', style: TextStyle(fontSize: 43)),
          ),
          const SizedBox(height: 15),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            userEmail,
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 30),
          profileOption(
            Icons.account_balance_wallet_outlined,
            'Total Income',
            currency.format(totalIncome),
          ),
          profileOption(
            Icons.receipt_long_outlined,
            'Total Expenses',
            currency.format(totalExpenses),
          ),
          profileOption(
            Icons.savings_outlined,
            'Available Balance',
            currency.format(balance),
          ),
          profileOption(
            Icons.info_outline,
            'App Version',
            '1.0.0',
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'HisaBoo • Manage money smartly 💙',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget profileOption(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: brightBlue),
          const SizedBox(width: 13),
          Expanded(child: Text(title)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      overviewPage(),
      reportsPage(),
      profilePage(),
    ];

    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: brightBlue),
            )
          : SafeArea(
              child: IndexedStack(
                index: selectedPage,
                children: pages,
              ),
            ),
      floatingActionButton: selectedPage == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openEntryForm(),
              backgroundColor: brightBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            ),
      bottomNavigationBar: isLoading
          ? null
          : NavigationBar(
              backgroundColor: navyBlue,
              indicatorColor: brightBlue.withValues(alpha: 0.25),
              selectedIndex: selectedPage,
              onDestinationSelected: (index) {
                setState(() => selectedPage = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}

// -------------------- ADD / EDIT ENTRY FORM --------------------

class EntryFormSheet extends StatefulWidget {
  final Expense? existing;

  const EntryFormSheet({super.key, this.existing});

  @override
  State<EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends State<EntryFormSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController amountController;
  late final TextEditingController notesController;

  late String type;
  late String category;
  late String paymentMethod;
  late DateTime selectedDate;

  final List<String> paymentMethods = [
    'Cash',
    'UPI',
    'Debit Card',
    'Credit Card',
    'Bank Transfer',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    titleController = TextEditingController(text: existing?.title ?? '');
    amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toString(),
    );
    notesController = TextEditingController(text: existing?.notes ?? '');

    type = existing?.type ?? 'Expense';
    category = existing?.category ?? 'Food';
    paymentMethod = existing?.paymentMethod ?? 'Cash';
    selectedDate = existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: brightBlue,
              surface: navyBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void saveEntry() {
    if (!formKey.currentState!.validate()) return;

    final amount = double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) return;

    final entry = Expense(
      title: titleController.text.trim(),
      amount: amount,
      category: category,
      date: selectedDate,
      type: type,
      paymentMethod: paymentMethod,
      notes: notesController.text.trim(),
    );

    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        22,
        22,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                isEditing ? '✏️ Edit Entry' : '✨ Add New Entry',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Transaction Type',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 9),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Expense',
                    label: Text('Expense'),
                    icon: Icon(Icons.trending_down),
                  ),
                  ButtonSegment(
                    value: 'Income',
                    label: Text('Income'),
                    icon: Icon(Icons.trending_up),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (value) {
                  setState(() => type = value.first);
                },
              ),
              const SizedBox(height: 17),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.edit_note),
                  hintText: 'e.g. Grocery shopping',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                dropdownColor: cardColor,
                items: categories.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text('${emojis[item]}  $item'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => category = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.payment),
                ),
                dropdownColor: cardColor,
                items: paymentMethods.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: chooseDate,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: brightBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('dd MMMM yyyy').format(selectedDate),
                        ),
                      ),
                      const Icon(Icons.edit_calendar, color: brightBlue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Add a short note...',
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 53,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brightBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: saveEntry,
                  child: Text(
                    isEditing ? 'Update Entry ✓' : 'Save Entry ✓',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
