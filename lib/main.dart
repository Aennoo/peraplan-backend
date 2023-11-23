// main.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:peraplan/styles.dart';
import 'database.dart'; // Import the backend code

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TransactionScreen(),
    );
  }
}

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late Box<Transaction> _transactionBox;
  TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedCategory;
  String? _selectedTransactionType;

  @override
  void initState() {
    super.initState();
    _transactionBox = Hive.box<Transaction>('transactions');
  }

  void _addTransaction() {
    // Parse the amount from the string to double
    double parsedAmount = double.tryParse(_amountController.text) ?? 0.0;

    Transaction newTransaction;

    if (_selectedTransactionType == 'Pera In') {
      newTransaction = PeraIn(
        amount: parsedAmount,
        date: _selectedDate,
        time: _selectedTime,
        category: _selectedCategory,
      );
    } else if (_selectedTransactionType == 'Pera Out') {
      newTransaction = PeraOut(
        amount: parsedAmount,
        date: _selectedDate,
        time: _selectedTime,
        category: _selectedCategory,
      );
    } else {
      // Handle other cases or throw an error if needed
      return;
    }

    _transactionBox.add(newTransaction);
    _amountController.clear();

    setState(() {});
  }

  double calculateBalance() {
    double peraInTotal = 0.0;
    double peraOutTotal = 0.0;

    for (int i = 0; i < _transactionBox.length; i++) {
      final transaction = _transactionBox.getAt(i);

      if (transaction is PeraIn) {
        peraInTotal += transaction.amount;
      } else if (transaction is PeraOut) {
        peraOutTotal += transaction.amount;
      }
    }

    return peraInTotal - peraOutTotal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction App'),
      ),
      body: Column(
        children: [
          Text(
            'Balance: ${calculateBalance().toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Dropdown for Transaction Type
          DropdownButtonFormField<String>(
            value: _selectedTransactionType,
            items: ['Pera In', 'Pera Out']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedTransactionType = newValue;
                });
              }
            },
            decoration: InputDecoration(labelText: 'Transaction Type'),
          ),
          SizedBox(height: medium),

          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Amount'),
          ),
          SizedBox(height: xsmall),

          Row(
            children: [
              Text('Date:'),
              SizedBox(width: xsmall),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != _selectedDate) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
                child: Text('Select Date'),
              ),
              SizedBox(width: xsmall),
              Text('${DateFormat('yyyy-MM-dd').format(_selectedDate)}')
            ],
          ),
          SizedBox(height: xsmall),
          Row(
            children: [
              Text('Time:'),
              SizedBox(width: xsmall),
              ElevatedButton(
                onPressed: () async {
                  final TimeOfDay? timeOfDay = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                    initialEntryMode: TimePickerEntryMode.dial,
                  );
                  if (timeOfDay != null) {
                    setState(() {
                      _selectedTime = timeOfDay;
                    });
                  }
                },
                child: Text('Select Time'),
              ),
              SizedBox(width: xsmall),
              Text(
                  '${_selectedTime.format(context)}') // Display the selected time
            ],
          ),
          SizedBox(height: xsmall),

          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: ['Food', 'Transportation', 'Shopping', 'Others']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedCategory = newValue;
                });
              }
            },
            decoration: InputDecoration(labelText: 'Category'),
          ),
          ElevatedButton(
            onPressed: _addTransaction,
            child: Text('Add Transaction'),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _transactionBox.listenable(),
              builder: (context, Box<Transaction> box, _) {
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final transaction = box.getAt(index);

// Determine the transaction type
                    String transactionType = '';
                    if (transaction is PeraIn) {
                      transactionType = 'Pera In';
                    } else if (transaction is PeraOut) {
                      transactionType = 'Pera Out';
                    }

                    return ListTile(
                      title: Text('${transactionType}'),
                      subtitle: Text(
                          'Amount: ${transaction?.amount}\nDate: ${DateFormat('yyyy-MM-dd').format(transaction?.date ?? DateTime.now())}\nTime: ${transaction?.time ?? TimeOfDay.now()}\nCategory: ${transaction?.category}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
