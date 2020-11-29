import 'package:flutter/material.dart';
import 'package:glutter/models/monitoring/cpu.dart';
import 'package:glutter/models/monitoring/memory.dart';
import 'package:glutter/models/monitoring/pluginsList.dart';
import 'package:glutter/models/monitoring/sensor.dart';
import 'package:glutter/models/shared/profile.dart';
import 'package:glutter/services/monitoring/glances_service.dart';
import 'package:glutter/services/shared/preferences_service.dart';
import 'package:glutter/widgets/drawer.dart';
import 'package:glutter/widgets/errors.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:glutter/models/monitoring/pluginsList.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({Key key, this.title: "Dashboard"}) : super(key: key);

  static const String routeName = '/dashboard';
  final String title;

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<DashboardScreen> {
  Profile selectedProfile;
  GlancesService glancesService;
  Future<PluginsList> pluginsListFuture;
  PluginsList pluginsList;
  Future<CPU> cpuFuture;
  Future<Memory> memFuture;
  Future<List<Sensor>> sensFuture;

  @override
  void initState() {
    super.initState();

    PreferencesService.getLastProfile().then((profile) => () {
        this.selectedProfile = profile;
        _refreshDashboardData();
      });
  }

  RefreshController _refreshController = RefreshController(initialRefresh: false);

  void _onRefresh() async {
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 500));

    this.setState(() {
      PreferencesService.getLastProfile().then((profile) => () {
          this.selectedProfile = profile;
          _refreshDashboardData();
        });
    });

    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  void _refreshDashboardData() {
    this.glancesService = new GlancesService(this.selectedProfile);
    this.cpuFuture = glancesService.getCpu();
    this.memFuture = glancesService.getMemory();
    this.sensFuture = glancesService.getSensors();
    this.pluginsListFuture = glancesService.getPluginsList();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: AppDrawer(),
      body: SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        header: ClassicHeader(),
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          child: FutureBuilder<Profile>(
            future: PreferencesService.getLastProfile(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                this.selectedProfile = snapshot.data;
                _refreshDashboardData();
                return _createMainDashboardColumn();
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }
          )
        )
      )
    );
  }

  Widget _createMainDashboardColumn() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text(
                  'Server ' + this.selectedProfile.caption,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  )
                ),
                subtitle: Text('Address: ' + this.selectedProfile.serverAddress),
                trailing: Container(
                  width: 150,
                  child: FutureBuilder(
                    future: pluginsListFuture,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.active:
                        case ConnectionState.waiting:
                          return Container(child: new CircularProgressIndicator(), alignment: Alignment(1.0, 0.0));
                        case ConnectionState.done:
                          bool online = (snapshot.data != null) ? true : false;
                          String status = online ? "online" : "unreachable";
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                status,
                                style: TextStyle(
                                  color: online ? Colors.green : Colors.grey,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 15.0
                                ),
                              ),
                              SizedBox(width: 7.5),
                              Container(
                                width: 30,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: online ? Colors.green : null
                                ),
                                child: Container(
                                    alignment: Alignment.center,
                                    child: online ? Icon(Icons.check) : Icon(Icons.help_outline)
                                ),
                              ),
                            ]
                          );
                          return SizedBox();

                        default:
                          return SizedBox();
                      }
                    }
                  )
                )
              )
            ]
          ),
        ),
        FutureBuilder(
          future: cpuFuture,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.active:
              case ConnectionState.waiting:
                return Center(
                  child: Container(
                    child: new CircularProgressIndicator(),
                    alignment: Alignment(0.0, 0.0)
                  )
                );
              case ConnectionState.done:
                if (snapshot.data != null) {
                  return Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        const ListTile(leading: Icon(Icons.memory), title: Text("CPU Usage")),
                        Container(
                          child: CircularPercentIndicator(
                            radius: 150.0,
                            animation: true,
                            lineWidth: 15.0,
                            percent: (snapshot.data.totalLoad / 100),
                            center: new Text(snapshot.data.totalLoad.toString() + "%"),
                            progressColor: Theme.of(context).accentColor,
                            backgroundColor: Theme.of(context).primaryColor,
                          )
                        )
                      ],
                    )
                  );
                }
                return showNoDataReceived("CPU", this.selectedProfile);

              default:
                return Text("An internal error occured. Please try again.");
            }
          }
        ),
        FutureBuilder(
          future: memFuture,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.active:
              case ConnectionState.waiting:
                return Container(child: Container(child: new CircularProgressIndicator(), alignment: Alignment(0.0, 0.0)));
              case ConnectionState.done:
                if (snapshot.data != null) {
                  return Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        const ListTile(
                          leading: Icon(Icons.storage),
                          title: Text("Memory Usage"),
                        ),
                        Center(
                          child: CircularPercentIndicator(
                            radius: 150.0,
                            animation: true,
                            lineWidth: 15.0,
                            percent: (snapshot.data.usagePercent / 100),
                            center: new Text(snapshot.data.usagePercent.toString() + "%"),
                            progressColor: Theme.of(context).accentColor,
                            backgroundColor: Theme.of(context).primaryColor,
                          )
                        )
                      ],
                    ),
                  );
                }
                return showNoDataReceived("Memory", this.selectedProfile);

              default:
                return Text("An internal error occured. Please try again.");
            }
          }
        ),
        FutureBuilder(
          future: sensFuture,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.active:
              case ConnectionState.waiting:
                return Container(child: Container(child: new CircularProgressIndicator(), alignment: Alignment(0.0, 0.0)));
              case ConnectionState.done:
                if (snapshot.data != null) {
                  if (snapshot.data.length > 0) {
                    return Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          const ListTile(
                            leading: Icon(Icons.toys),
                            title: Text("Sensors"),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: List.generate(snapshot.data.length, (i) {
                              return Center(
                                child: CircularPercentIndicator(
                                  radius: 150.0,
                                  animation: true,
                                  lineWidth: 15.0,
                                  header: new Text(snapshot.data[i].label),
                                  percent: (snapshot.data[i].value / 100),
                                  center: new Text(snapshot.data[i].value.toString() + " " + snapshot.data[i].unit.toString()),
                                  progressColor: Theme.of(context).accentColor,
                                  backgroundColor: Theme.of(context).primaryColor,
                                )
                              );
                            })
                          )
                        ],
                      ),
                    );
                  } else {
                    return SizedBox();
                  }
                } else {
                  return showNoDataReceived("Sensors", this.selectedProfile);
                }
                return SizedBox();

              default:
                return Text("An internal error occured. Please try again.");
            }
          }
        )
      ],
    );
  }
}
