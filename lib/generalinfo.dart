import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';

class AverageCalculationPage extends StatefulWidget {
  const AverageCalculationPage({Key? key}) : super(key: key);

  @override
  State<AverageCalculationPage> createState() => _AverageCalculationPageState();
}

class _AverageCalculationPageState extends State<AverageCalculationPage> {
  String? _selectedColumn;
  int? _selectedHour;
  double? _average;

  @override
  void initState() {
    super.initState();
    // Load data when the page is initialized
    Provider.of<DataProvider>(context, listen: false).loadData();
  }

  double? _calculateHourlyAverage(int hour, String column) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    int columnIndex = dataProvider.columns.indexOf(column); // Adjust index
    int startRow = (hour - 1) * 3600;
    int endRow = startRow + 3600;

    if (startRow >= dataProvider.data.length) return null;
    if (endRow > dataProvider.data.length) endRow = dataProvider.data.length;

    List<List<dynamic>> rows = dataProvider.data.sublist(startRow, endRow);

    double sum = 0;
    int validCount = 0;
    for (var row in rows) {
      try {
        double value = double.parse(row[columnIndex].toString());
        sum += value;
        validCount++;
      } catch (e) {
        print("Error parsing double at row $row, column $columnIndex: $e");
      }
    }

    return validCount > 0 ? sum / validCount : null;
  }

  void _calculateAverage() {
    if (_selectedHour != null && _selectedColumn != null) {
      double? avg = _calculateHourlyAverage(_selectedHour!, _selectedColumn!);
      setState(() {
        _average = avg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AE9000"),
      ),
      body: dataProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dataProvider.errorMessage != null
              ? Center(child: Text(dataProvider.errorMessage!))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButton<String>(
                        hint: const Text("Select Column"),
                        value: _selectedColumn,
                        items: dataProvider.columns.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedColumn = newValue;
                          });
                        },
                      ),
                      DropdownButton<int>(
                        hint: const Text("Select Hour"),
                        value: _selectedHour,
                        items: [
                          for (int i = 1;
                              i <= (dataProvider.data.length) ~/ 3600;
                              i++)
                            DropdownMenuItem<int>(
                              value: i,
                              child: Text('Hour $i'),
                            ),
                        ],
                        onChanged: (newValue) {
                          setState(() {
                            _selectedHour = newValue;
                          });
                        },
                      ),
                      ElevatedButton(
                        onPressed: _calculateAverage,
                        child: const Text("Calculate Average"),
                      ),
                      if (_average != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Text(
                            'Average ${_selectedColumn!} for Hour ${_selectedHour!}: ${_average!.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/charts');
                        },
                        child: const Text("Go to Charts"),
                      ),
                    ],
                  ),
                ),
    );
  }
}
