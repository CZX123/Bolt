import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_database/ui/firebase_list.dart';
import 'package:firebase_database/ui/firebase_sorted_list.dart';

/// An AnimatedList widget that is bound to a query
class FirebaseSliverAnimatedList extends StatefulWidget {
  /// Creates a scrolling container that animates items when they are inserted or removed.
  FirebaseSliverAnimatedList({
    Key key,
    @required this.query,
    @required this.itemBuilder,
    this.sort,
    this.defaultChild,
    this.duration = const Duration(milliseconds: 300),
  })  : assert(itemBuilder != null),
        super(key: key);

  /// A Firebase query to use to populate the animated list
  final Query query;

  /// Optional function used to compare snapshots when sorting the list
  ///
  /// The default is to sort the snapshots by key.
  final Comparator<DataSnapshot> sort;

  /// A widget to display while the query is loading. Defaults to an empty
  /// Container().
  final Widget defaultChild;

  /// Called, as needed, to build list item widgets.
  ///
  /// List items are only built when they're scrolled into view.
  ///
  /// The [DataSnapshot] parameter indicates the snapshot that should be used
  /// to build the item.
  ///
  /// Implementations of this callback should assume that [AnimatedList.removeItem]
  /// removes an item immediately.
  final FirebaseAnimatedListItemBuilder itemBuilder;

  /// The duration of the insert and remove animation.
  ///
  /// Defaults to const Duration(milliseconds: 300).
  final Duration duration;

  @override
  FirebaseSliverAnimatedListState createState() =>
      FirebaseSliverAnimatedListState();
}

class FirebaseSliverAnimatedListState
    extends State<FirebaseSliverAnimatedList> {
  final GlobalKey<SliverAnimatedListState> _animatedListKey =
      GlobalKey<SliverAnimatedListState>();
  List<DataSnapshot> _model;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    if (widget.sort != null) {
      _model = FirebaseSortedList(
        query: widget.query,
        comparator: widget.sort,
        onChildAdded: _onChildAdded,
        onChildRemoved: _onChildRemoved,
        onChildChanged: _onChildChanged,
        onValue: _onValue,
      );
    } else {
      _model = FirebaseList(
        query: widget.query,
        onChildAdded: _onChildAdded,
        onChildRemoved: _onChildRemoved,
        onChildChanged: _onChildChanged,
        onChildMoved: _onChildMoved,
        onValue: _onValue,
      );
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Cancel the Firebase stream subscriptions
    _model.clear();

    super.dispose();
  }

  void _onChildAdded(int index, DataSnapshot snapshot) {
    if (!_loaded) {
      return; // AnimatedList is not created yet
    }
    _animatedListKey.currentState.insertItem(index, duration: widget.duration);
  }

  void _onChildRemoved(int index, DataSnapshot snapshot) {
    // The child should have already been removed from the model by now
    assert(index >= _model.length || _model[index].key != snapshot.key);
    _animatedListKey.currentState.removeItem(
      index,
      (BuildContext context, Animation<double> animation) {
        return widget.itemBuilder(context, snapshot, animation, index);
      },
      duration: widget.duration,
    );
  }

  // No animation, just update contents
  void _onChildChanged(int index, DataSnapshot snapshot) {
    setState(() {});
  }

  // No animation, just update contents
  void _onChildMoved(int fromIndex, int toIndex, DataSnapshot snapshot) {
    setState(() {});
  }

  void _onValue(DataSnapshot _) {
    setState(() {
      _loaded = true;
    });
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return widget.itemBuilder(context, _model[index], animation, index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return widget.defaultChild ?? SliverToBoxAdapter();
    }
    return SliverAnimatedList(
      key: _animatedListKey,
      itemBuilder: _buildItem,
      initialItemCount: _model.length,
    );
  }
}
