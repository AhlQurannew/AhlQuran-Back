import 'package:get/get.dart';

class ChartConfigController extends GetxController {
  // Default values
  RxDouble yAxisMin = 0.0.obs;
  RxDouble yAxisMax = 100.0.obs;
  RxDouble yAxisInterval = 10.0.obs;

  void setYAxisRange(double min, double max, [double interval = 10]) {
    yAxisMin.value = min;
    yAxisMax.value = max;
    yAxisInterval.value = interval;
    update();
  }

  // Helper method to calculate appropriate range based on data
  void autoCalculateRange(List<double> values) {
    if (values.isEmpty) {
      setYAxisRange(0, 100);
      return;
    }

    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);

    // Add some padding (10% of range)
    final range = dataMax - dataMin;
    final padding = range * 0.1;

    // Calculate nice intervals
    final interval = _calculateNiceInterval(dataMax - dataMin);

    setYAxisRange(
      (dataMin - padding).clamp(0, double.infinity),
      (dataMax + padding).clamp(0, double.infinity),
      interval,
    );
  }

  double _calculateNiceInterval(double range) {
    // Calculate nice intervals (1, 2, 5, 10, 20, 50, etc.)
    final exponent = range.floor().toString().length - 1;
    final fraction = range / (10 ^ exponent);

    if (fraction <= 2) return 0.2 * (10 ^ exponent);
    if (fraction <= 5) return 0.5 * (10 ^ exponent);
    return 1 * (10 ^ exponent).toDouble();
  }
}
