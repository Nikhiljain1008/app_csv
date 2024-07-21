import 'dart:async';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<List<dynamic>> _data = [];
  List<String> _columns = [];
  String? _selectedColumn;
  int? _selectedHour;
  bool _isLoading = true;
  String? _errorMessage;
  double? _average;
  int availableHours = 0;
  int _currentIndex = 0; // To track the current page index
  List<String> selectedColumns = []; // For selected columns using chips
  String? _selectedTimePeriod;
  List<String> timePeriods = [
    '5 minutes',
    '30 minutes',
    '3 hours',
    '1 day'
  ]; // Time periods for selection

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final rawData = await rootBundle.loadString("assets/data2.csv");
      List<List<dynamic>> listData =
          const CsvToListConverter().convert(rawData);

      setState(() {
        _data = listData.sublist(1); // Skip the header row
        _columns = listData[0]
            .sublist(2)
            .map((col) => col.toString())
            .toList(); // Skip first two columns (Time and Date)
        availableHours = (_data.length) ~/ 3600;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  double? _calculateHourlyAverage(int hour, String column) {
    int columnIndex = _columns.indexOf(column) +
        2; // Adjust index to account for excluded columns
    int startRow = (hour - 1) * 3600;
    int endRow = startRow + 3600;

    if (startRow >= _data.length) return null;
    if (endRow > _data.length) endRow = _data.length;

    List<List<dynamic>> rows = _data.sublist(startRow, endRow);

    double sum = 0;
    for (var row in rows) {
      sum += double.parse(row[columnIndex].toString());
    }

    return sum / rows.length;
  }

  void _calculateAverage() {
    if (_selectedHour != null && _selectedColumn != null) {
      double? avg = _calculateHourlyAverage(_selectedHour!, _selectedColumn!);
      setState(() {
        _average = avg;
      });
    }
  }

  Widget _buildChoiceList() {
    List<Widget> choices = [];

    _columns.forEach((item) {
      choices.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item),
          selected: selectedColumns.contains(item),
          onSelected: (selected) {
            setState(() {
              selectedColumns.contains(item)
                  ? selectedColumns.remove(item)
                  : selectedColumns.add(item);
            });
          },
        ),
      ));
    });

    return Wrap(
      children: choices,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Data Visualization App"),
        ),
        body: IndexedStack(
          children: <Widget>[
            _buildFirstPage(),
            _buildSecondPage(),
            _buildGraphPage(), // Third page to show graphs
          ],
          index: _currentIndex,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.file_present),
              label: 'Data',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.select_all),
              label: 'Select Columns',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Graph',
            ),
          ],
          currentIndex: _currentIndex,
          selectedItemColor: Colors.amber[800],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFirstPage() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButton<String>(
                      hint: const Text("Select Column"),
                      value: _selectedColumn,
                      items: _columns.map((String value) {
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
                        for (int i = 1; i <= availableHours; i++)
                          DropdownMenuItem<int>(
                            value: i,
                            child: Text('Hour $i'),
                          ),
                      ],
                      onChanged: (newValue) {
                        print("Selected Hour: $newValue");
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
                  ],
                ),
              );
  }

  Widget _buildSecondPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Select Columns",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          _buildChoiceList(),
          SizedBox(height: 20),
          DropdownButton<String>(
            hint: const Text("Select Time Period"),
            value: _selectedTimePeriod,
            items: timePeriods.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedTimePeriod = newValue;
              });
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentIndex = 2; // Switch to the graph page
              });
            },
            child: const Text("Generate Graph"),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: selectedColumns.map((column) {
            List<double> columnData = _data.map((row) {
              return double.parse(row[_columns.indexOf(column) + 2]
                  .toString()); // Adjust index to account for excluded columns
            }).toList();
            return buildLineChartContainer(column, columnData);
          }).toList(),
        ),
      ),
    );
  }

  Widget buildLineChartContainer(String title, List<double> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            backgroundColor: Colors.black,
            color: Colors.white,
          ),
        ),
        Container(
          height: 200, // Adjust the height as needed
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: data
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  color: Colors.blue,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                  barWidth: 2,
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(color: Colors.black, fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(color: Colors.black, fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
