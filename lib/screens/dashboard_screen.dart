import 'package:flutter/material.dart';
import 'package:splitapp/widgets/show_add_split.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(title: Text("Split App"),centerTitle: true,),
      body: Column(
        children: [
          
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:() => showAddSplitDialog(context),
        tooltip: 'Add Split',
        child: Icon(Icons.add),
         ),
    );
  }
}