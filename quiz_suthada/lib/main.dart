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

                double totalIncome = 0;
                double totalExpense = 0;
                for (var doc in snapshot.data!.docs) {
                  double amount = (doc['amount'] as num).toDouble();
                  if (doc['type'] == 'รายจ่าย') {
                    totalExpense += amount;
                  } else {
                    totalIncome += amount;
                  }
                }

                List<Map<String, dynamic>> lastTwoMonthsData =
                    _prepareLastTwoMonthsData(snapshot.data!);

                Widget chartWidget = _buildBarChart(lastTwoMonthsData);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'ยอดคงเหลือ: ${(totalIncome - totalExpense).toStringAsFixed(2)}',
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

  List<Map<String, dynamic>> _prepareLastTwoMonthsData(QuerySnapshot snapshot) {
    DateTime now = DateTime.now();
    DateTime lastMonth = DateTime(now.year, now.month - 1, 1);
    DateTime twoMonthsAgo = DateTime(now.year, now.month - 2, 1);

    double lastMonthIncome = 0;
    double lastMonthExpense = 0;
    double twoMonthsAgoIncome = 0;
    double twoMonthsAgoExpense = 0;

    for (var doc in snapshot.docs) {
      DateTime entryDate = doc['date'].toDate();
      double amount = (doc['amount'] as num).toDouble();

      if (entryDate.isAfter(lastMonth) && entryDate.isBefore(now)) {
        if (doc['type'] == 'รายรับ') {
          lastMonthIncome += amount;
        } else {
          lastMonthExpense += amount;
        }
      } else if (entryDate.isAfter(twoMonthsAgo) &&
          entryDate.isBefore(lastMonth)) {
        if (doc['type'] == 'รายรับ') {
          twoMonthsAgoIncome += amount;
        } else {
          twoMonthsAgoExpense += amount;
        }
      }
    }

    return [
      {
        'month': lastMonth.month.toDouble(), // Store the month as double
        'income': lastMonthIncome,
        'expense': lastMonthExpense
      },
      {
        'month': twoMonthsAgo.month.toDouble(), // Store the month as double
        'income': twoMonthsAgoIncome,
        'expense': twoMonthsAgoExpense
      },
    ];
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
            barGroups: [
              BarChartGroupData(
                x: 1, // Last Month
                barRods: [
                  BarChartRodData(
                    toY: data[0]['income'],
                    color: Colors.green[500], // Change to a cohesive color
                    width: 25, // Thicker bars
                    borderRadius: BorderRadius.circular(8),
                  ),
                  BarChartRodData(
                    toY: data[0]['expense'],
                    color: Colors.red[500], // Change to a cohesive color
                    width: 25, // Thicker bars
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 2, // Two Months Ago
                barRods: [
                  BarChartRodData(
                    toY: data[1]['income'],
                    color: Colors.green[500],
                    width: 25,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  BarChartRodData(
                    toY: data[1]['expense'],
                    color: Colors.red[500],
                    width: 25,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false), // Hide left titles
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() == 1) {
                      return Text('${data[0]['month']}/2023',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold));
                    } else if (value.toInt() == 2) {
                      return Text('${data[1]['month']}/2023',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold));
                    } else {
                      return const Text('');
                    }
                  },
                ),
              ),
            ),
            gridData: FlGridData(show: false), // Hide grid lines
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
            ),
            alignment: BarChartAlignment.spaceAround,
            maxY: data[0]['income'] > data[1]['income']
                ? data[0]['income'] * 1.2
                : data[1]['income'] * 1.2,
          ),
        ),
      ),
    );
  }

  // Function to add new entry
  void _addEntry() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      return; // Handle invalid input
    }

    FirebaseFirestore.instance
        .collection(FirebaseAuth.instance.currentUser!.email!)
        .add({
      'amount': amount,
      'type': _selectedType,
      'date': _selectedDate,
      'note': _noteController.text,
    });

    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedType = 'รายรับ';
    });
  }

  // Function to delete entry
  void _deleteEntry(String id) {
    FirebaseFirestore.instance
        .collection(FirebaseAuth.instance.currentUser!.email!)
        .doc(id)
        .delete();
  }
}
