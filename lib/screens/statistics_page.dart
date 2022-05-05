import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/constants.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/model/weight_entry.dart';
import 'package:weight_tracker/screens/weight_entry_dialog.dart';
import 'package:weight_tracker/widgets/progress_chart.dart';

class _StatisticsPageViewModel {
  final double? totalProgress;
  final double? currentWeight;
  final double? last7daysProgress;
  final double? last30daysProgress;
  final List<WeightEntry>? entries;
  final String? unit;
  final Function()? openAddEntryDialog;

  _StatisticsPageViewModel({
    this.last7daysProgress,
    this.last30daysProgress,
    this.totalProgress,
    this.currentWeight,
    this.entries,
    this.unit,
    this.openAddEntryDialog,
  });
}

class StatisticsPage extends StatelessWidget {

  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<ReduxState, _StatisticsPageViewModel>(
      converter: (store) {
        String unit = store.state.unit;
        List<WeightEntry> entries = [];
        for (var entry in store.state.entries) {
          if (unit == "kg") {
            entries.add(entry);
          } else {
            entries.add(entry.copyWith(weight: entry.weight * KG_LBS_RATIO));
          }
        }
        List<WeightEntry> last7daysEntries = entries
            .where((entry) =>
            entry.dateTime
                .isAfter(DateTime.now().subtract(const Duration(days: 7))))
            .toList();
        List<WeightEntry> last30daysEntries = entries
            .where((entry) =>
            entry.dateTime
                .isAfter(DateTime.now().subtract(const Duration(days: 30))))
            .toList();
        return _StatisticsPageViewModel(
          totalProgress: entries.isEmpty
              ? 0.0
              : (entries.first.weight - entries.last.weight),
          currentWeight: entries.isEmpty ? 0.0 : entries.first.weight,
          last7daysProgress: last7daysEntries.isEmpty
              ? 0.0
              : (last7daysEntries.first.weight - last7daysEntries.last.weight),
          last30daysProgress: last30daysEntries.isEmpty
              ? 0.0
              : (last30daysEntries.first.weight -
              last30daysEntries.last.weight),
          entries: entries,
          unit: unit,
          openAddEntryDialog: () {
            if (last30daysEntries.isEmpty) {
              store.dispatch(OpenAddEntryDialog());
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) {
                  return WeightEntryDialog();
                },
                fullscreenDialog: true,
              ));
            }
          },
        );
      },
      builder: (context, viewModel) {
        return ListView(
          children: <Widget>[
            GestureDetector(
              onTap: viewModel.openAddEntryDialog,
              child: _StatisticCardWrapper(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ProgressChart()),
                height: 250.0,
              ),
            ),
            _StatisticCard(
              title: "Current weight",
              value: viewModel.currentWeight!,
              unit: viewModel.unit!,
            ),
            _StatisticCard(
              title: "Progress done",
              value: viewModel.totalProgress!,
              processNumberSymbol: true,
              unit: viewModel.unit!,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: _StatisticCard(
                    title: "Last week",
                    value: viewModel.last7daysProgress!,
                    textSizeFactor: 0.8,
                    processNumberSymbol: true,
                    unit: viewModel.unit!,
                  ),
                ),
                Expanded(
                  child: _StatisticCard(
                    title: "Last month",
                    value: viewModel.last30daysProgress!,
                    textSizeFactor: 0.8,
                    processNumberSymbol: true,
                    unit: viewModel.unit!,
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }
}

class _StatisticCardWrapper extends StatelessWidget {
  final double height;
  final Widget? child;

  _StatisticCardWrapper({this.height = 120.0, this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: height,
            child: Card(child: child),
          ),
        ),
      ],
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String? title;
  final num? value;
  final bool? processNumberSymbol;
  final double? textSizeFactor;
  final String? unit;

  const _StatisticCard({this.title,
    this.value,
    this.unit,
    this.processNumberSymbol = false,
    this.textSizeFactor = 1.0});

  @override
  Widget build(BuildContext context) {
    Color numberColor =
    (processNumberSymbol! && (value! > 0)) ? Colors.red : Colors.green;
    String numberSymbol = processNumberSymbol! && (value! > 0) ? "+" : "";
    return _StatisticCardWrapper(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Row(
              children: [
                Text(
                  numberSymbol + value!.toStringAsFixed(1),
                  textScaleFactor: textSizeFactor,
                  style: Theme
                      .of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(color: numberColor),
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text(unit!)),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ),
          Padding(
            child: Text(title ?? ""),
            padding: const EdgeInsets.only(bottom: 8.0),
          ),
        ],
      ),
    );
  }
}
