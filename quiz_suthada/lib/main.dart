import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:quiz_suthada/screen/signin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SigninScreen(),
        '/home': (context) => const IncomeExpenseApp(),
      },
    );
  }
}

class IncomeExpenseApp extends StatefulWidget {
  const IncomeExpenseApp({super.key});

  @override
  State<IncomeExpenseApp> createState() => _IncomeExpenseAppState();
}

class _IncomeExpenseAppState extends State<IncomeExpenseApp> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'รายรับ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกรายรับรายจ่าย'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    const Text('วันที่: '),
                    TextButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Text(_selectedDate.toString().split(' ')[0]),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: _selectedType,
                  items: ['รายรับ', 'รายจ่าย'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                ),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'หมายเหตุ'),
                ),
                ElevatedButton(
                  onPressed: _addEntry,
                  child: const Text('เพิ่มรายการ'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseAuth.instance.currentUser!.email!)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('ยังไม่มีรายการ'));
                }

                List<Map<String, dynamic>> monthlyData =
                    _prepareMonthlyData(snapshot.data!);
                Widget chartWidget = _buildBarChart(monthlyData);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'ยอดคงเหลือ: ${_calculateBalance(snapshot.data!)} บาท',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: chartWidget,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index];
                          return ListTile(
                            title: Text(
                              '${doc['type']}: ${doc['amount']} บาท',
                              style: TextStyle(
                                  color: doc['type'] == 'รายรับ'
                                      ? Colors.green
                                      : Colors.red),
                            ),
                            subtitle: Text(
                              'วันที่: ${doc['date'].toDate().toString().split(' ')[0]}\n'
                              'หมายเหตุ: ${doc['note']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteEntry(doc.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBalance(QuerySnapshot snapshot) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var doc in snapshot.docs) {
      double amount = (doc['amount'] as num).toDouble();
      if (doc['type'] == 'รายจ่าย') {
        totalExpense += amount;
      } else {
        totalIncome += amount;
      }
    }
    return totalIncome - totalExpense;
  }

  List<Map<String, dynamic>> _prepareMonthlyData(QuerySnapshot snapshot) {
    Map<String, double> monthlyIncome = {};
    Map<String, double> monthlyExpense = {};

    for (var doc in snapshot.docs) {
      DateTime entryDate = doc['date'].toDate();
      String monthYear =
          "${entryDate.year}-${entryDate.month.toString().padLeft(2, '0')}";

      double amount = (doc['amount'] as num).toDouble();
      if (doc['type'] == 'รายรับ') {
        monthlyIncome[monthYear] = (monthlyIncome[monthYear] ?? 0) + amount;
      } else {
        monthlyExpense[monthYear] = (monthlyExpense[monthYear] ?? 0) + amount;
      }
    }

    List<Map<String, dynamic>> chartData = [];
    monthlyIncome.forEach((key, income) {
      chartData.add({
        'month': key,
        'income': income,
        'expense': monthlyExpense[key] ?? 0,
      });
    });

    return chartData;
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: BarChart(
          BarChartData(
            barGroups: data.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> monthData = entry.value;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: monthData['income'],
                    color: Colors.green[500],
                    width: 25,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  BarChartRodData(
                    toY: monthData['expense'],
                    color: Colors.red[500],
                    width: 25,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < data.length) {
                      return Text(
                        data[value.toInt()]
                            ['month'], // Display month-year as title
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      );
                    } else {
                      return const Text('');
                    }
                  },
                ),
              ),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
            ),
            alignment: BarChartAlignment.spaceAround,
            maxY: data.map((e) => e['income']).reduce((a, b) => a > b ? a : b) *
                1.2,
          ),
        ),
      ),
    );
  }

  void _addEntry() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      return; // Handle invalid input
    }

    FirebaseFirestore.instance
        .collection(FirebaseAuth.instance.currentUser!.email!)
        .add({
      'amount': amount,
      'date': _selectedDate,
      'type': _selectedType,
      'note': _noteController.text,
    });

    _amountController.clear();
    _noteController.clear();
  }

  void _deleteEntry(String id) {
    FirebaseFirestore.instance
        .collection(FirebaseAuth.instance.currentUser!.email!)
        .doc(id)
        .delete();
  }
}
