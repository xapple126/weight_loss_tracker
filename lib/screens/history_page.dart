import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:meta/meta.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/model/weight_entry.dart';
import 'package:weight_tracker/screens/weight_entry_dialog.dart';
import 'package:weight_tracker/widgets/weight_list_item.dart';

@immutable
class HistoryPageViewModel {
  final String? unit;
  final List<WeightEntry>? entries;
  final bool? hasEntryBeenRemoved;
  final Function()? acceptEntryRemoved;
  final Function()? undoEntryRemoval;
  final Function(WeightEntry)? openEditDialog;

  HistoryPageViewModel({
    this.undoEntryRemoval,
    this.hasEntryBeenRemoved,
    this.acceptEntryRemoved,
    this.entries,
    this.openEditDialog,
    this.unit,
  });
}

class HistoryPage extends StatelessWidget {
  HistoryPage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<ReduxState, HistoryPageViewModel>(
      converter: (store) {
        return HistoryPageViewModel(
          entries: store.state.entries,
          openEditDialog: (entry) {
            store.dispatch(OpenEditEntryDialog(entry));
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) {
                return WeightEntryDialog();
              },
              fullscreenDialog: true,
            ));
          },
          hasEntryBeenRemoved: store.state.removedEntryState
              .hasEntryBeenRemoved,
          acceptEntryRemoved: () =>
              store.dispatch(AcceptEntryRemovalAction()),
          undoEntryRemoval: () => store.dispatch(UndoRemovalAction()),
          unit: store.state.unit,
        );
      },
      builder: (context, viewModel) {
        if (viewModel.hasEntryBeenRemoved!) {
          Future<void>.delayed(Duration.zero, () {
            Scaffold.of(context).showSnackBar(SnackBar(
              content: const Text("Entry deleted."),
              action: SnackBarAction(
                label: "UNDO",
                onPressed: () => viewModel.undoEntryRemoval!(),
              ),
            ));
            viewModel.acceptEntryRemoved!();
          });
        }
        if (viewModel.entries!.isEmpty) {
          return const Center(
            child: Text("Add your weight to see history"),
          );
        } else {
          return ListView.builder(
            shrinkWrap: true,
            itemCount: viewModel.entries!.length,
            itemBuilder: (buildContext, index) {
              //calculating difference
              double difference = index == viewModel.entries!.length - 1
                  ? 0.0
                  : viewModel.entries![index].weight -
                  viewModel.entries![index + 1].weight;
              return InkWell(
                  onTap: () =>
                      viewModel.openEditDialog!(viewModel.entries![index]),
                  child: WeightListItem(
                      viewModel.entries![index], difference, viewModel.unit!));
            },
          );
        }
      },
    );
  }
}
