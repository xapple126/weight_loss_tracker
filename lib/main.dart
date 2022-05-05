import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:weight_tracker/screens/main_page.dart';

import 'logic/actions.dart';
import 'logic/middleware.dart';
import 'logic/reducer.dart';
import 'logic/redux_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final Store<ReduxState> store = Store<ReduxState>(reduce,
      initialState: const ReduxState(
          entries: [],
          unit: 'kg',
          removedEntryState: RemovedEntryState(hasEntryBeenRemoved: false),
          firebaseState: FirebaseState(),
          mainPageState: MainPageReduxState(hasEntryBeenAdded: false),
          weightEntryDialogState: WeightEntryDialogReduxState()),
      middleware: [middleware].toList());

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    store.dispatch(InitAction());
    return StoreProvider(
      store: store,
      child: MaterialApp(
        title: 'Weight Loss Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue
        ),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: analytics),
        ],
        home: MainPage(title: 'Weight Loss Tracker', analytics: analytics),
      ),
    );
  }
}