import 'dart:io';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:band_names/models/band.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();

    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text(
          'Band Names',
          style: TextStyle(color: Colors.black87),
        ),
        actions: <Widget>[
          Container(
              margin: EdgeInsets.only(right: 10.0),
              child: socketService.serverStatus == ServerStatus.Online
                  ? Icon(Icons.check_circle,
                      size: 45.0, color: Colors.blue[300])
                  : Icon(Icons.offline_bolt,
                      size: 45.0, color: Colors.red[300]))
        ],
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, i) => _bandTile(bands[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewBand,
        child: Icon(
          Icons.add,
          size: 25.0,
        ),
        elevation: 1,
      ),
    );
  }

  Widget _bandTile(Band band) {
    final SocketService socketService =
        Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) =>
          socketService.socket.emit('delete-band', {'id': band.id}),
      background: Container(
        padding: EdgeInsets.only(left: 8.0),
        color: Colors.redAccent,
        child: Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.delete_outline, color: Colors.white, size: 35.0)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0, 2)),
          backgroundColor: Colors.blue[200],
        ),
        title: Text(band.name),
        trailing: Text(
          '${band.votes}',
          style: TextStyle(fontSize: 20.0),
        ),
        onTap: () => socketService.socket.emit('vote-band', {'id': band.id}),
      ),
    );
  }

  addNewBand() {
    final textController = TextEditingController();

    if (Platform.isIOS) {
      return showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
                title: Text('New band name'),
                content: CupertinoTextField(
                  controller: textController,
                ),
                actions: <Widget>[
                  CupertinoDialogAction(
                      isDefaultAction: true,
                      child: Text('Add'),
                      onPressed: () => addBandToList(textController.text)),
                  CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: Text('Dismiss'),
                      onPressed: () => Navigator.pop(context)),
                ],
              ));
    }
    if (Platform.isAndroid) {
      return showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text('New band name'),
                content: TextField(
                  controller: textController,
                ),
                actions: <Widget>[
                  MaterialButton(
                      child: Text('Add'),
                      elevation: 5,
                      textColor: Colors.blue,
                      onPressed: () => addBandToList(textController.text))
                ],
              ));
    }
  }

  void addBandToList(String name) {
    print(name);
    if (name.length > 1) {
      // Se puede agregar
      final SocketService serverSocket =
          Provider.of<SocketService>(context, listen: false);
      serverSocket.socket.emit('add-band', {'name': name});
    }
    Navigator.pop(context);
  }

  Widget _showGraph() {
    Map<String, double> dataMap = new Map();
    // dataMap.putIfAbsent('Flutter', () => 5);
    bands.forEach((band) { 
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    // COLOR LIST PARA EL PIE CHART FULL
    // final List<Color> colorList = [
    //   Colors.blue[50],
    //   Colors.blue[200],
    //   Colors.pink[50],
    //   Colors.pink[200],
    //   Colors.yellow[50],
    //   Colors.yellow[200],
    //   Colors.deepOrange[50],
    //   Colors.deepOrange[200],


    // ];
    return Container(
      width: double.infinity, 
      height: 200, 
      child: PieChart(
        dataMap:dataMap
      ),

    
    //   child: PieChart(
    //     dataMap: dataMap,
    //     animationDuration: Duration(milliseconds: 800),
    //     chartLegendSpacing: 32.0,
    //     chartRadius: MediaQuery.of(context).size.width / 2.7,
    //     showChartValuesInPercentage: true,
    //     showChartValues: true,
    //     showChartValuesOutside: false,
    //     chartValueBackgroundColor: Colors.grey[200],
    //     colorList: d,
    //     showLegends: true,
    //     legendPosition: LegendPosition.right,
    //     decimalPlaces: 1,
    //     showChartValueLabel: true,
    //     initialAngle: 0,
    //     chartValueStyle: defaultChartValueStyle.copyWith(
    //       color: Colors.blueGrey[900].withOpacity(0.9),
    //     ),
    //     chartType: ChartType.disc,
    // )
    );
  }
}
