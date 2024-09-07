import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';

class ChartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Data Chart"),
      ),
      body: Column(
        children: [
          // Chart display
          Expanded(
            child: ListView.builder(
              itemCount: dataProvider.selectedColumns.length,
              itemBuilder: (context, index) {
                final column = dataProvider.selectedColumns[index];
                final chartData = dataProvider.getFilteredChartData(column);
                return Card(
                  child: Column(
                    children: [
                      Text(column),
                      Container(
                        height: 300,
                        child: SfCartesianChart(
                          primaryXAxis: DateTimeAxis(),
                          series: <CartesianSeries>[
                            LineSeries<ChartData, DateTime>(
                              dataSource: chartData,
                              xValueMapper: (ChartData data, _) =>
                                  data.dateTime,
                              yValueMapper: (ChartData data, _) => data.value,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
