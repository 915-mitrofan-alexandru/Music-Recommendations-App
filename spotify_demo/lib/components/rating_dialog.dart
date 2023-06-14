import 'package:flutter/material.dart';

class RatingDialog extends StatefulWidget {
  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _stars = 1;

  Widget buildStar(int starCount) {
    return InkWell(
      child: Icon(
        Icons.star,
        // size: 30.0,
        color: _stars >= starCount ? Colors.orange : Colors.grey,
      ),
      onTap: () {
        setState(() {
          _stars = starCount;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: Text('Rate this song'),),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          buildStar(1),
          buildStar(2),
          buildStar(3),
          buildStar(4),
          buildStar(5),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('CANCEL'),
          onPressed: Navigator.of(context).pop,
        ),
        TextButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(_stars.toString());
          },
        )
      ],
    );
  }
}