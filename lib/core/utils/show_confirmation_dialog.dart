import 'package:flutter/material.dart';

//confimation dialog pop up
Future<bool?> showConfirmationDialog (BuildContext context, String text, IconData icon) async {
  return showDialog(
    context: context, 
    builder: (BuildContext context){
      return AlertDialog(
        title: Row(
          children: [
            Icon(icon, ),
            SizedBox(width: 10,),
            Text(
              text,
              style: TextStyle(
                fontSize: 20
              ),
            ),
          ],
        ),
        //backgroundColor: AppPallete.backgroundColor,
        // content: Text(''),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.of(context).pop(true);
            },
            
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: (){
              Navigator.of(context).pop(false);
            }, 
            child: Text('No')
          )
        ],
      );
    }
  );
}