import 'package:app_csv/chartdisplaypage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';

class SelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Select Columns and Time"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Column selection chips
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0,
                children: dataProvider.columns.map((column) {
                  final isSelected =
                      dataProvider.selectedColumns.contains(column);
                  return FilterChip(
                    label: Text(column),
                    selected: isSelected,
                    onSelected: (selected) {
                      List<String> newSelection =
                          List.from(dataProvider.selectedColumns);
                      if (selected) {
                        newSelection.add(column);
                      } else {
                        newSelection.remove(column);
                      }
                      dataProvider.setSelectedColumns(newSelection);
                    },
                  );
                }).toList(),
              ),
            ),

            // Start Date and Time Picker
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (selectedDate != null) {
                        TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (selectedTime != null) {
                          DateTime startDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          dataProvider.setStartDateTime(startDateTime);
                        }
                      }
                    },
                    child: Text("Select Start Date & Time"),
                  ),
                  SizedBox(height: 10),
                  Text(dataProvider.startDateTime != null
                      ? "Start: ${DateFormat('yyyy-MM-dd HH:mm').format(dataProvider.startDateTime!)}"
                      : "No start date selected"),
                ],
              ),
            ),

            // End Date and Time Picker
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (selectedDate != null) {
                        TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (selectedTime != null) {
                          DateTime endDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          dataProvider.setEndDateTime(endDateTime);
                        }
                      }
                    },
                    child: Text("Select End Date & Time"),
                  ),
                  SizedBox(height: 10),
                  Text(dataProvider.endDateTime != null
                      ? "End: ${DateFormat('yyyy-MM-dd HH:mm').format(dataProvider.endDateTime!)}"
                      : "No end date selected"),
                ],
              ),
            ),

            // Button to view the graph
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  if (dataProvider.selectedColumns.isNotEmpty &&
                      dataProvider.startDateTime != null &&
                      dataProvider.endDateTime != null) {
                    Navigator.pushNamed(context, '/chartPage');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Please select columns and time period.'),
                    ));
                  }
                },
                child: Text("View Graph"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
