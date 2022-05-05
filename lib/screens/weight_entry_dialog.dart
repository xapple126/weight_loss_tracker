import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/constants.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/model/weight_entry.dart';

import '../widgets/number_picker.dart';

class DialogViewModel {
  final WeightEntry? weightEntry;
  final String? unit;
  final bool? isEditMode;
  final double? weightToDisplay;
  final Function(WeightEntry)? onEntryChanged;
  final Function()? onDeletePressed;
  final Function()? onSavePressed;

  DialogViewModel({
    this.weightEntry,
    this.unit,
    this.isEditMode,
    this.weightToDisplay,
    this.onEntryChanged,
    this.onDeletePressed,
    this.onSavePressed,
  });
}

class WeightEntryDialog extends StatefulWidget {
  const WeightEntryDialog({Key? key}) : super(key: key);

  @override
  State<WeightEntryDialog> createState() {
    return WeightEntryDialogState();
  }
}

class WeightEntryDialogState extends State<WeightEntryDialog> {
  TextEditingController? _textController;
  bool wasBuiltOnce = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<ReduxState, DialogViewModel>(
      converter: (store) {
        WeightEntry? activeEntry =
            store.state.weightEntryDialogState.activeEntry;
        return DialogViewModel(
            weightEntry: activeEntry,
            unit: store.state.unit,
            isEditMode: store.state.weightEntryDialogState.isEditMode,
            weightToDisplay: store.state.unit == "kg"
                ? activeEntry!.weight
                : double.parse(
                (activeEntry!.weight * KG_LBS_RATIO).toStringAsFixed(1)),
            onEntryChanged: (entry) =>
                store.dispatch(UpdateActiveWeightEntry(entry)),
            onDeletePressed: () {
              store.dispatch(RemoveEntryAction(activeEntry));
              Navigator.of(context).pop();
            },
            onSavePressed: () {
              if (store.state.weightEntryDialogState.isEditMode!) {
                store.dispatch(EditEntryAction(activeEntry));
              } else {
                store.dispatch(AddEntryAction(activeEntry));
              }
              Navigator.of(context).pop();
            });
      },
      builder: (context, viewModel) {
        if (!wasBuiltOnce) {
          wasBuiltOnce = true;
          _textController?.text = viewModel.weightEntry!.note;
        }
        return Scaffold(
          appBar: _createAppBar(context, viewModel),
          body: Column(
            children: [
              ListTile(
                leading: Icon(Icons.today, color: Colors.grey[500]),
                title: DateTimeItem(
                  dateTime: viewModel.weightEntry!.dateTime,
                  onChanged: (dateTime) =>
                      viewModel.onEntryChanged!(
                          viewModel.weightEntry!..dateTime = dateTime),
                ),
              ),
              ListTile(
                leading: Image.asset(
                  "assets/scale-bathroom.png",
                  color: Colors.grey[500],
                  height: 24.0,
                  width: 24.0,
                ),
                title: Text(
                  viewModel.weightToDisplay!.toStringAsFixed(1) +
                      " " +
                      viewModel.unit!,
                ),
                onTap: () => _showWeightPicker(context, viewModel),
              ),
              ListTile(
                leading: Icon(Icons.speaker_notes, color: Colors.grey[500]),
                title: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Optional note',
                    ),
                    controller: _textController,
                    onChanged: (value) {
                      viewModel.onEntryChanged!(viewModel.weightEntry!..note = value);
                    }),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSize _createAppBar(BuildContext context, DialogViewModel viewModel) {
    TextStyle actionStyle =
    Theme
        .of(context)
        .textTheme
        .subtitle1
        !.copyWith(color: Colors.white);
    Text title = viewModel.isEditMode!
        ? const Text("Edit entry")
        : const Text("New entry");
    List<Widget> actions = [];
    if (viewModel.isEditMode!) {
      actions.add(
        TextButton(
          onPressed: viewModel.onDeletePressed,
          child: Text(
            'DELETE',
            style: actionStyle,
          ),
        ),
      );
    }
    actions.add(TextButton(
      onPressed: viewModel.onSavePressed,
      child: Text(
        'SAVE',
        style: actionStyle,
      ),
    ));

    return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: title,
          actions: actions,
        ),
    );
  }

  _showWeightPicker(BuildContext context, DialogViewModel viewModel) {
    showDialog<double>(
      context: context,
      builder: (context) =>
      NumberPickerDialog.decimal(
        minValue: viewModel.unit == "kg"
            ? MIN_KG_VALUE
            : (MIN_KG_VALUE * KG_LBS_RATIO).toInt(),
        maxValue: viewModel.unit == "kg"
            ? MAX_KG_VALUE
            : (MAX_KG_VALUE * KG_LBS_RATIO).toInt(),
        initialDoubleValue: viewModel.weightToDisplay!,
        title: const Text("Enter your weight"),
      ),
    ).then((double? value) {
      if (value != null) {
        if (viewModel.unit == "lbs") {
          value = value / KG_LBS_RATIO;
        }
        viewModel.onEntryChanged!(viewModel.weightEntry!..weight = value);
      }
    });
  }
}

class DateTimeItem extends StatelessWidget {
  DateTimeItem({Key? key, DateTime? dateTime, required this.onChanged})
      : date = dateTime == null
            ? DateTime.now()
            : DateTime(dateTime.year, dateTime.month, dateTime.day),
        time = dateTime == null
            ? TimeOfDay.now()
            : TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
        super(key: key);

  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: InkWell(
            key: const Key('CalendarItem'),
            onTap: (() => _showDatePicker(context)),
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(DateFormat('EEEE, MMMM d').format(date))),
          ),
        ),
        InkWell(
          key: const Key('TimeItem'),
          onTap: (() => _showTimePicker(context)),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(time.format(context))),
        ),
      ],
    );
  }

  Future _showDatePicker(BuildContext context) async {
    DateTime? dateTimePicked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: date.subtract(const Duration(days: 365)),
        lastDate: DateTime.now());

    if (dateTimePicked != null) {
      onChanged(DateTime(dateTimePicked.year, dateTimePicked.month,
          dateTimePicked.day, time.hour, time.minute));
    }
  }

  Future _showTimePicker(BuildContext context) async {
    TimeOfDay? timeOfDay =
    await showTimePicker(context: context, initialTime: time);

    if (timeOfDay != null) {
      onChanged(DateTime(
          date.year, date.month, date.day, timeOfDay.hour, timeOfDay.minute));
    }
  }
}
