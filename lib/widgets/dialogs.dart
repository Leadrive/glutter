import 'package:flutter/material.dart';

class ConfirmLeaveDialog extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want to leave without saving? You are going to lose your changes!'),
            actions: <Widget>[
                new FlatButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: new Text("Cancel"),
                ),
                new FlatButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: new Text('Discard'),
                ),
            ],
        );
    }
}
