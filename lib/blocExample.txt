// Just an example of the bloc pattern, nothing to see here

import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeBloc _themeBloc = ThemeBloc();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        accentColor: Colors.purpleAccent,
      ),
      home: BlocProvider<ThemeBloc>(
        bloc: _themeBloc,
        child: MyHomePage(title: 'BOLT'),
      ),
    );
  }

  @override
  void dispose() {
    _themeBloc.dispose();
    super.dispose();
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final ThemeBloc _themeBloc = BlocProvider.of<ThemeBloc>(context);
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(
                0.0, MediaQuery.of(context).padding.top + 16.0, 0.0, 16.0),
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 4.0,
              ),
            ),
          ),
          Center(
            child: BlocBuilder<ThemeEvent, int>(
              bloc: _themeBloc,
              builder: (BuildContext context, int _theme) {
                return Text(
                  '$_theme',
                  style: const TextStyle(
                    fontSize: 64.0,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          const SizedBox(),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              _themeBloc.dispatch(ThemeEvent.increment);
            },
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
          SizedBox(width: 12.0),
          FloatingActionButton(
            onPressed: () {
              _themeBloc.dispatch(ThemeEvent.decrement);
            },
            tooltip: 'Decrement',
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}

enum ThemeEvent { increment, decrement }

class ThemeBloc extends Bloc<ThemeEvent, int> {
  @override
  int get initialState => 0;

  @override
  Stream<int> mapEventToState(ThemeEvent event) async* {
    switch (event) {
      case ThemeEvent.decrement:
        yield currentState - 1;
        break;
      case ThemeEvent.increment:
        yield currentState + 1;
        break;
    }
  }
}
