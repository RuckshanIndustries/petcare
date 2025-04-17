import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';


class ReportsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Reports'),
      ),
      child: FutureBuilder<QuerySnapshot>(
        future: _firestore.collection('appointments').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CupertinoActivityIndicator());
          }
          var appointments = snapshot.data!.docs;

          // Group appointments by type
          Map<String, int> appointmentCounts = {};
          appointments.forEach((appointment) {
            String type = appointment['type'];
            appointmentCounts[type] = (appointmentCounts[type] ?? 0) + 1;
          });

          // Convert to chart data
          List<ChartData> chartData = appointmentCounts.entries
              .map((entry) => ChartData(entry.key, entry.value))
              .toList();

          return SfCircularChart(
            title: ChartTitle(text: 'Appointments by Type'),
            legend: Legend(isVisible: true),
            series: <CircularSeries>[
              PieSeries<ChartData, String>(
                dataSource: chartData,
                xValueMapper: (ChartData data, _) => data.type,
                yValueMapper: (ChartData data, _) => data.count,
                dataLabelSettings: DataLabelSettings(isVisible: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChartData {
  final String type;
  final int count;

  ChartData(this.type, this.count);
}
