import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HisaBooApp());
}

const cream = Color(0xFFFFFBF3);
const paper = Color(0xFFFFFDF9);
const ink = Color(0xFF34352F);
const muted = Color(0xFF858477);
const green = Color(0xFF728B70);
const sage = Color(0xFFE5EBDD);
const peach = Color(0xFFF7E2D4);
const lilac = Color(0xFFEAE5F4);
const yellow = Color(0xFFF5EDCE);

const categories = [
  'Food & Dining',
  'Transportation',
  'Shopping',
  'Entertainment',
  'Education',
  'Healthcare',
  'Utilities',
  'Other',
];
const payments = ['UPI', 'Cash', 'Debit Card', 'Credit Card', 'Net Banking'];

class Expense {
  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.payment,
    this.note = '',
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String payment;
  final String note;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'payment': payment,
        'note': note,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        date: DateTime.parse(map['date'] as String),
        payment: map['payment'] as String,
        note: (map['note'] ?? '') as String,
      );
}

class HisaBooApp extends StatefulWidget {
  const HisaBooApp({super.key});

  @override
  State<HisaBooApp> createState() => _HisaBooAppState();
}

class _HisaBooAppState extends State<HisaBooApp> {
  bool loading = true;
  String userName = '';
  String userEmail = '';
  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('expenses') ?? '[]';
    final decoded = jsonDecode(raw) as List<dynamic>;
    setState(() {
      userName = prefs.getString('userName') ?? '';
      userEmail = prefs.getString('userEmail') ?? '';
      expenses = decoded
          .map((item) => Expense.fromMap(Map<String, dynamic>.from(item)))
          .toList();
      loading = false;
    });
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'expenses',
      jsonEncode(expenses.map((expense) => expense.toMap()).toList()),
    );
  }

  Future<void> _saveProfile(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    setState(() {
      userName = name;
      userEmail = email;
    });
  }

  Future<void> _saveExpense(Expense expense) async {
    setState(() {
      final index = expenses.indexWhere((item) => item.id == expense.id);
      if (index == -1) {
        expenses.insert(0, expense);
      } else {
        expenses[index] = expense;
      }
      expenses.sort((a, b) => b.date.compareTo(a.date));
    });
    await _saveExpenses();
  }

  Future<void> _deleteExpense(String id) async {
    setState(() => expenses.removeWhere((item) => item.id == id));
    await _saveExpenses();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    setState(() {
      userName = '';
      userEmail = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HisaBoo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          primary: green,
          surface: cream,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: paper,
          hintStyle: const TextStyle(color: muted),
          labelStyle: const TextStyle(color: muted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFECE8DD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFECE8DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
        ),
      ),
      home: loading
          ? const SplashScreen()
          : userName.isEmpty
              ? WelcomeScreen(onContinue: _saveProfile)
              : HomeShell(
                  userName: userName,
                  userEmail: userEmail,
                  expenses: expenses,
                  onSave: _saveExpense,
                  onDelete: _deleteExpense,
                  onLogout: _logout,
                ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandMark(),
              SizedBox(height: 14),
              Text('HisaBoo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink)),
              Text('A little more mindful, every day', style: TextStyle(color: muted)),
            ],
          ),
        ),
      );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: sage,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: Text('H', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: green)),
        ),
      );
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinue});
  final Future<void> Function(String, String) onContinue;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    if (name.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and a valid email.')),
      );
      return;
    }
    await widget.onContinue(name, email);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: BrandMark()),
                  const SizedBox(height: 26),
                  const Text('Your money,', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: ink)),
                  const Text('your little story.', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: green)),
                  const SizedBox(height: 10),
                  const Text('Keep track of everyday spending and make room for what matters.', style: TextStyle(color: muted, height: 1.5)),
                  const SizedBox(height: 30),
                  const Text('Let’s get to know you', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: ink)),
                  const SizedBox(height: 16),
                  TextField(controller: nameController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Your name', prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 13),
                  TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline))),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _continue,
                      style: FilledButton.styleFrom(backgroundColor: green, padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Get started  →', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(child: Text('Your records stay on this device.', style: TextStyle(color: muted, fontSize: 12))),
                ],
              ),
            ),
          ),
        ),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.expenses,
    required this.onSave,
    required this.onDelete,
    required this.onLogout,
  });

  final String userName;
  final String userEmail;
  final List<Expense> expenses;
  final Future<void> Function(Expense) onSave;
  final Future<void> Function(String) onDelete;
  final Future<void> Function() onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedIndex = 0;

  Future<void> _openForm([Expense? expense]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(existing: expense, onSave: widget.onSave),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        userName: widget.userName,
        expenses: widget.expenses,
        onAdd: () => _openForm(),
        onSeeAll: () => setState(() => selectedIndex = 1),
      ),
      TransactionsScreen(
        expenses: widget.expenses,
        onEdit: _openForm,
        onDelete: widget.onDelete,
      ),
      ProfileScreen(
        userName: widget.userName,
        userEmail: widget.userEmail,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: selectedIndex, children: pages)),
      floatingActionButton: selectedIndex == 2
          ? null
          : FloatingActionButton(
              onPressed: () => _openForm(),
              backgroundColor: green,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded, size: 30),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) => setState(() => selectedIndex = value),
        backgroundColor: paper,
        indicatorColor: sage,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.userName, required this.expenses, required this.onAdd, required this.onSeeAll});
  final String userName;
  final List<Expense> expenses;
  final VoidCallback onAdd;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthItems = expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    final monthTotal = monthItems.fold<double>(0, (sum, e) => sum + e.amount);
    final allTotal = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final recent = [...expenses]..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
      children: [
        Row(
          children: [
            const BrandMark(),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('HISABOO', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, color: green)),
              Text('little steps, smart savings', style: TextStyle(color: muted, fontSize: 11)),
            ])),
            CircleAvatar(backgroundColor: peach, child: Text(userName.isEmpty ? 'H' : userName[0].toUpperCase(), style: const TextStyle(color: ink, fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 26),
        Text('Hello, ${userName.split(' ').first} 👋', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
        const Text('Here’s your money snapshot.', style: TextStyle(color: muted)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7F987C), Color(0xFF5F7D65)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TOTAL SPENT THIS MONTH', style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            Text('₹${money(monthTotal)}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.calendar_month_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(DateFormat('MMMM yyyy').format(now), style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              Text('${monthItems.length} transactions', style: const TextStyle(color: Colors.white)),
            ]),
          ]),
        ),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: StatCard(title: 'All-time spending', value: '₹${money(allTotal)}', icon: Icons.account_balance_wallet_outlined, tint: lilac)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(title: 'This month', value: '${monthItems.length} items', icon: Icons.auto_graph_rounded, tint: yellow)),
        ]),
        const SizedBox(height: 25),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Spending by category', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
          Text('${monthItems.length} entries', style: const TextStyle(color: muted, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        CategoryBreakdown(expenses: monthItems),
        const SizedBox(height: 25),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Recent activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ]),
        if (recent.isEmpty)
          EmptyState(title: 'No expenses yet', subtitle: 'Add your first expense to see it here.', onAction: onAdd)
        else
          ...recent.take(4).map((e) => ExpenseTile(expense: e)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add a new expense'), style: OutlinedButton.styleFrom(foregroundColor: green, side: const BorderSide(color: green), padding: const EdgeInsets.symmetric(vertical: 14))),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.tint});
  final String title;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFECE8DD))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 17, backgroundColor: tint, child: Icon(icon, size: 17, color: ink)),
          const SizedBox(height: 13),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ink)),
          Text(title, style: const TextStyle(fontSize: 11, color: muted)),
        ]),
      );
}

class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({super.key, required this.expenses});
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Text('Your category summary will appear after adding expenses.', style: TextStyle(color: muted, fontSize: 13));
    }
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sorted.first.value;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFECE8DD))),
      child: Column(children: sorted.take(5).map((entry) {
        final tint = categoryColor(entry.key);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(entry.key, style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600))),
              Text('₹${money(entry.value)}', style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 7),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: entry.value / maxValue, minHeight: 7, backgroundColor: const Color(0xFFF0EEE6), color: tint)),
          ]),
        );
      }).toList()),
    );
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.expenses, required this.onEdit, required this.onDelete});
  final List<Expense> expenses;
  final ValueChanged<Expense> onEdit;
  final Future<void> Function(String) onDelete;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String query = '';
  String category = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.expenses.where((e) {
      final matchesQuery = e.title.toLowerCase().contains(query.toLowerCase()) || e.category.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = category == 'All' || e.category == category;
      return matchesQuery && matchesCategory;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 90),
      children: [
        const Text('Your activity', style: TextStyle(color: green, letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('All expenses', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
        const Text('Every little purchase, in one place.', style: TextStyle(color: muted)),
        const SizedBox(height: 18),
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search expenses'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: category,
          decoration: const InputDecoration(labelText: 'Filter by category'),
          items: ['All', ...categories].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (value) => setState(() => category = value ?? 'All'),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Text('${filtered.length} transaction${filtered.length == 1 ? '' : 's'}', style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('Total: ₹${money(filtered.fold<double>(0, (s, e) => s + e.amount))}', style: const TextStyle(color: green, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const EmptyState(title: 'Nothing to show', subtitle: 'Try another search or add a new expense.')
        else
          ...filtered.map((expense) => Dismissible(
                key: ValueKey(expense.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(color: const Color(0xFFF4DCD7), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete expense?'),
                    content: Text('Remove "${expense.title}" from your records?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                    ],
                  ),
                ),
                onDismissed: (_) => widget.onDelete(expense.id),
                child: ExpenseTile(
                  expense: expense,
                  onEdit: () => widget.onEdit(expense),
                  onDelete: () => widget.onDelete(expense.id),
                ),
              )),
      ],
    );
  }
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, this.onEdit, this.onDelete});
  final Expense expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFECE8DD))),
        child: Row(children: [
          CircleAvatar(backgroundColor: categoryColor(expense.category).withOpacity(.17), child: Icon(categoryIcon(expense.category), color: categoryColor(expense.category), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 3),
            Text('${expense.category} • ${DateFormat('dd MMM yyyy').format(expense.date)}', style: const TextStyle(color: muted, fontSize: 10)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${money(expense.amount)}', style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
            if (onEdit != null || onDelete != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(visualDensity: VisualDensity.compact, tooltip: 'Edit', onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 17, color: green)),
                IconButton(visualDensity: VisualDensity.compact, tooltip: 'Delete', onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 17, color: Colors.redAccent)),
              ])
            else
              Text(expense.payment, style: const TextStyle(color: muted, fontSize: 10)),
          ]),
        ]),
      );
}

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.existing, required this.onSave});
  final Expense? existing;
  final Future<void> Function(Expense) onSave;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController amountController;
  late final TextEditingController noteController;
  late String selectedCategory;
  late String selectedPayment;
  late DateTime selectedDate;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final old = widget.existing;
    titleController = TextEditingController(text: old?.title ?? '');
    amountController = TextEditingController(text: old == null ? '' : old.amount.toStringAsFixed(2));
    noteController = TextEditingController(text: old?.note ?? '');
    selectedCategory = old?.category ?? categories.first;
    selectedPayment = old?.payment ?? payments.first;
    selectedDate = old?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: green, surface: cream)), child: child!),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final expense = Expense(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      amount: double.parse(amountController.text.trim()),
      category: selectedCategory,
      date: selectedDate,
      payment: selectedPayment,
      note: noteController.text.trim(),
    );
    await widget.onSave(expense);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.existing == null ? 'Add expense' : 'Edit expense', style: const TextStyle(fontWeight: FontWeight.w800))),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: sage, borderRadius: BorderRadius.circular(20)),
                child: const Row(children: [
                  Icon(Icons.spa_outlined, color: green, size: 28),
                  SizedBox(width: 12),
                  Expanded(child: Text('Small entries make a clearer picture. Add the details below.', style: TextStyle(color: ink, height: 1.4))),
                ]),
              ),
              const SizedBox(height: 22),
              const FieldLabel('Expense name'),
              TextFormField(controller: titleController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'e.g. Grocery shopping'), validator: (v) => v == null || v.trim().isEmpty ? 'Please enter an expense name' : null),
              const SizedBox(height: 16),
              const FieldLabel('Amount (₹)'),
              TextFormField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0.00', prefixText: '₹ '), validator: (v) {
                final value = double.tryParse(v ?? '');
                if (value == null || value <= 0) return 'Enter an amount greater than zero';
                return null;
              }),
              const SizedBox(height: 16),
              const FieldLabel('Category'),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => selectedCategory = v ?? categories.first),
              ),
              const SizedBox(height: 16),
              const FieldLabel('Payment method'),
              DropdownButtonFormField<String>(
                value: selectedPayment,
                decoration: const InputDecoration(),
                items: payments.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => selectedPayment = v ?? payments.first),
              ),
              const SizedBox(height: 16),
              const FieldLabel('Transaction date'),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_outlined)),
                  child: Text(DateFormat('dd MMMM yyyy').format(selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              const FieldLabel('Note (optional)'),
              TextFormField(controller: noteController, maxLines: 3, decoration: const InputDecoration(hintText: 'Add a short note...')),
              const SizedBox(height: 25),
              FilledButton(
                onPressed: saving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: green, padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(widget.existing == null ? 'Save expense' : 'Update expense', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 13)));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.userName, required this.userEmail, required this.onLogout});
  final String userName;
  final String userEmail;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 14),
          const Text('A little about you', style: TextStyle(color: green, letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          const Text('Your profile', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: peach, borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              CircleAvatar(radius: 34, backgroundColor: paper, child: Text(userName.isEmpty ? 'H' : userName[0].toUpperCase(), style: const TextStyle(fontSize: 27, color: green, fontWeight: FontWeight.w800))),
              const SizedBox(height: 12),
              Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
              Text(userEmail, style: const TextStyle(color: muted)),
            ]),
          ),
          const SizedBox(height: 20),
          const ListTile(leading: Icon(Icons.lock_outline, color: green), title: Text('Private local storage'), subtitle: Text('Your expense records are saved on this device.')),
          const ListTile(leading: Icon(Icons.palette_outlined, color: green), title: Text('HisaBoo theme'), subtitle: Text('Cream, ivory and soft pastel colours.')),
          const ListTile(leading: Icon(Icons.info_outline, color: green), title: Text('About'), subtitle: Text('HisaBoo Personal Expense Tracker • Flutter & Dart')),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () async {
              final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Log out?'),
                content: const Text('Your expense records will remain saved on this device.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
                ],
              ));
              if (yes == true) await onLogout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.subtitle, this.onAction});
  final String title;
  final String subtitle;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFECE8DD))),
        child: Column(children: [
          const Icon(Icons.receipt_long_outlined, size: 35, color: green),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
          if (onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: const Text('Add expense')),
          ],
        ]),
      );
}

String money(double amount) => NumberFormat('#,##0.00').format(amount);

Color categoryColor(String category) {
  switch (category) {
    case 'Food & Dining': return const Color(0xFFCB9872);
    case 'Transportation': return const Color(0xFF7E9DB5);
    case 'Shopping': return const Color(0xFFB08AB8);
    case 'Entertainment': return const Color(0xFFD39B9B);
    case 'Education': return const Color(0xFF829B78);
    case 'Healthcare': return const Color(0xFF86AAA4);
    case 'Utilities': return const Color(0xFFC3A75E);
    default: return green;
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Food & Dining': return Icons.restaurant_outlined;
    case 'Transportation': return Icons.directions_bus_outlined;
    case 'Shopping': return Icons.shopping_bag_outlined;
    case 'Entertainment': return Icons.movie_outlined;
    case 'Education': return Icons.menu_book_outlined;
    case 'Healthcare': return Icons.health_and_safety_outlined;
    case 'Utilities': return Icons.bolt_outlined;
    default: return Icons.spa_outlined;
  }
}
