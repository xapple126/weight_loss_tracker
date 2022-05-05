import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/screens/history_page.dart';
import 'package:weight_tracker/screens/settings_screen.dart';
import 'package:weight_tracker/screens/statistics_page.dart';
import 'package:weight_tracker/screens/weight_entry_dialog.dart';

class MainPageViewModel {
  final double? defaultWeight;
  final bool? hasEntryBeenAdded;
  final String? unit;
  final Function()? openAddEntryDialog;
  final Function()? acceptEntryAddedCallback;

  MainPageViewModel({
    this.openAddEntryDialog,
    this.defaultWeight,
    this.hasEntryBeenAdded,
    this.acceptEntryAddedCallback,
    this.unit,
  });
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key, this.title, this.analytics}) : super(key: key);
  final FirebaseAnalytics? analytics;
  final String? title;

  @override
  State<MainPage> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollViewController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scrollViewController = ScrollController();
    _tabController = TabController(vsync: this, length: 2);
  }

  @override
  void dispose() {
    _scrollViewController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<ReduxState, MainPageViewModel>(
      converter: (store) {
        return MainPageViewModel(
          defaultWeight: store.state.entries.isEmpty
              ? 60.0
              : store.state.entries.first.weight,
          hasEntryBeenAdded: store.state.mainPageState.hasEntryBeenAdded,
          acceptEntryAddedCallback: () =>
              store.dispatch(AcceptEntryAddedAction()),
          openAddEntryDialog: () {
            store.dispatch(OpenAddEntryDialog());
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) {
                return WeightEntryDialog();
              },
              fullscreenDialog: true,
            ));
            widget.analytics?.logEvent(name: 'open_add_dialog');
          },
          unit: store.state.unit,
        );
      },
      onInit: (store) {
        store.dispatch(GetSavedWeightNote());
      },
      builder: (context, viewModel) {
        if (viewModel.hasEntryBeenAdded!) {
          _scrollToTop();
          viewModel.acceptEntryAddedCallback!();
        }
        return Scaffold(
          body: NestedScrollView(
            controller: _scrollViewController,
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  title: Text(widget.title!),
                  pinned: true,
                  floating: true,
                  forceElevated: innerBoxIsScrolled,
                  bottom: TabBar(
                    tabs: const <Tab>[
                      Tab(
                        key: Key('StatisticsTab'),
                        text: "STATISTICS",
                        icon: Icon(Icons.show_chart),
                      ),
                      Tab(
                        key: Key('HistoryTab'),
                        text: "HISTORY",
                        icon: Icon(Icons.history),
                      ),
                    ],
                    controller: _tabController,
                  ),
                  actions: _buildMenuActions(context),
                ),
              ];
            },
            body: TabBarView(
              children: <Widget>[
                StatisticsPage(),
                HistoryPage(),
              ],
              controller: _tabController,
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => viewModel.openAddEntryDialog!(),
            tooltip: 'Add new weight entry',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  List<Widget> _buildMenuActions(BuildContext context) {
    return [
      IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _openSettingsPage(context)),
    ];
  }

  _scrollToTop() {
    _scrollViewController.animateTo(
      0.0,
      duration: const Duration(microseconds: 1),
      curve: const ElasticInCurve(0.01),
    );
  }

  _openSettingsPage(BuildContext context) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) {
        return SettingsPage();
      },
    ));
  }
}
