import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DataProvider with ChangeNotifier {
  List<List<dynamic>> _data = [];
  List<String> _columns = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _selectedColumns = [];
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  List<List<dynamic>> get data => _data;
  List<String> get columns => _columns;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get selectedColumns => _selectedColumns;
  DateTime? get startDateTime => _startDateTime;
  DateTime? get endDateTime => _endDateTime;

  Future<void> loadData() async {
    try {
      final rawData = await rootBundle.loadString("assets/cleaned_data.csv");
      List<List<dynamic>> listData =
          const CsvToListConverter().convert(rawData);

      _columns = listData[0].map((col) => col.toString()).toList();
      _data = listData.sublist(1); // Skip the header row
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Error loading data: $e';
      _isLoading = false;
    }
    notifyListeners();
  }

  void setSelectedColumns(List<String> columns) {
    _selectedColumns = columns;
    notifyListeners();
    print(_selectedColumns);
  }

  void setStartDateTime(DateTime? startDateTime) {
    _startDateTime = startDateTime;
    notifyListeners();
    print(_startDateTime);
  }

  void setEndDateTime(DateTime? endDateTime) {
    _endDateTime = endDateTime;
    notifyListeners();
    print(_endDateTime);
  }

  List<DateTime> getTimeSeries() {
    final List<DateTime> dateTimeSeries = [];
    final dateFormat = DateFormat('HH:mm, d/M/yyyy'); // Corrected format

    for (var row in _data) {
      try {
        String time = row[0].trim(); // Time in HH:mm
        String date = row[1].trim(); // Date in M/d/yyyy
        //print('Parsing time: $time, date: $date');
        DateTime dateTime = dateFormat.parse('$time, $date');
        dateTimeSeries.add(dateTime);
      } catch (e) {
        print('Error parsing data at row ${_data.indexOf(row)}: $e');
      }
    }
    print("successful first function");
    return dateTimeSeries;
  }

  List<ChartData> getFilteredChartData(String column) {
    final dateTimeSeries = getTimeSeries();
    final List<ChartData> chartData = [];

    print('DateTime Series: $dateTimeSeries');
    print('Start: $_startDateTime, End: $_endDateTime');

    for (int i = 0; i < dateTimeSeries.length; i++) {
      final dateTime = dateTimeSeries[i];
      if (_startDateTime != null &&
          _endDateTime != null &&
          (dateTime.isAfter(_startDateTime!) ||
              dateTime.isAtSameMomentAs(_startDateTime!)) &&
          (dateTime.isBefore(_endDateTime!) ||
              dateTime.isAtSameMomentAs(_endDateTime!))) {
        try {
          double value =
              double.parse(_data[i][_columns.indexOf(column)].toString());
          chartData.add(ChartData(dateTime, value));
        } catch (e) {
          print('Error parsing value at row $i: $e');
        }
      }
    }
    print('Filtered Chart Data: $chartData');
    return chartData;
  }
}

class ChartData {
  final DateTime dateTime;
  final double value;

  ChartData(this.dateTime, this.value);
}
