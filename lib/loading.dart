import 'library.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final windowPadding = Provider.of<EdgeInsets>(context);
    final double width = MediaQuery.of(context).size.width;
    if (width == 0) return SizedBox.shrink();
    final bool isDark = Provider.of<ThemeNotifier>(context).isDark;
    Color baseColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.14);
    Color highlightColor =
        isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.07);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Shimmer.fromColors(
          key: ValueKey(isDark),
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: width / 2560 * 1600 + 32,
            color: Colors.white,
          ),
        ),
        Positioned.fill(
          top: width / 2560 * 1600,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: kElevationToShadow[6],
            ),
            child: PhysicalShape(
              color: Color(Theme.of(context).scaffoldBackgroundColor.value),
              clipper: ShapeBorderClipper(
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Shimmer.fromColors(
                key: ValueKey(isDark),
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
                          height: 16,
                        ),
                        ClipRect(
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: (width - 72) / 2,
                              ),
                              for (int i = 0; i < 4; i++)
                                ClipRect(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 24),
                                    child: Container(
                                      height: 24,
                                      width: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 14,
                        ),
                        Center(
                          child: Container(
                            height: 2,
                            width: 96,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 36,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              height: 32,
                              width: 124,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
                              child: Container(
                                height: 32,
                                width: 112,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 42,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 13,
                            children: <Widget>[
                              for (int i = 0; i < 6; i++)
                                Column(
                                  children: <Widget>[
                                    ClipPath(
                                      clipper: ShapeBorderClipper(
                                        shape: ContinuousRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: Container(
                                        height: (width - 8.0 * 3) / 2,
                                        width: (width - 8.0 * 3) / 2,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 7,
                                    ),
                                    Container(
                                      height: 16,
                                      width: (width - 8.0 * 3) / 2 * .65,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Container(
                                      height: 14,
                                      width: (width - 8.0 * 3) / 2 * .25,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, windowPadding.bottom + 8),
            child: NoInternetWidget(),
          ),
        ),
      ],
    );
  }
}

class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisconnected = Provider.of<FirebaseConnectionState>(context) ==
        FirebaseConnectionState.disconnected;
    final dataIsNull = Provider.of<StallIdList>(context) == null;
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.ease,
        opacity: isDisconnected ? 1 : 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(60),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Text(
            dataIsNull ? 'Waiting for internet…' : 'No Internet',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
