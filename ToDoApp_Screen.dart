import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MyTodoApp extends StatefulWidget {
  @override
  State<MyTodoApp> createState() => _MyTodoAppState();
}

class _MyTodoAppState extends State<MyTodoApp> {
  TextEditingController itemController = TextEditingController();
  List<Map<String, dynamic>> itemList = [];
  final CollectionReference tasksCollection =
  FirebaseFirestore.instance.collection('tasks');

  void AddDataIntoList() async {
    String item = itemController.text.trim();
    if (item.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill the field!",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    try {
      await tasksCollection.add({"task": item, "isChecked": false});
      Fluttertoast.showToast(
        msg: "Task added successfully!",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
      itemController.clear();
      loadTasks();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to add task: $e",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> loadTasks() async {
    try {
      QuerySnapshot snapshot = await tasksCollection.get();
      setState(() {
        itemList = snapshot.docs.map((doc) {
          return {
            "id": doc.id,
            "task": doc["task"],
            "isChecked": doc["isChecked"],
          };
        }).toList();
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to load tasks: $e",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> updateTask(String id, bool isChecked) async {
    try {
      await tasksCollection.doc(id).update({"isChecked": isChecked});
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update task: $e",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await tasksCollection.doc(id).delete();
      Fluttertoast.showToast(
        msg: "Task removed successfully!",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
      loadTasks();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to delete task: $e",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> generatePdfReport() async {
    final pdf = pw.Document();
    final completedTasks = itemList.where((task) => task["isChecked"]).length;
    final pendingTasks = itemList.length - completedTasks;

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("To-Do App Task Report",
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Total Tasks: ${itemList.length}"),
            pw.Text("Completed Tasks: $completedTasks"),
            pw.Text("Pending Tasks: $pendingTasks"),
            pw.SizedBox(height: 20),
            pw.Text("Task Details:",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.ListView.builder(
              itemCount: itemList.length,
              itemBuilder: (context, index) {
                final task = itemList[index];
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Text(
                    "${index + 1}. ${task['task']} - ${task['isChecked'] ? 'Completed' : 'Pending'}",
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File("${output.path}/todo_report.pdf");
      await file.writeAsBytes(await pdf.save());
      Fluttertoast.showToast(
        msg: "PDF report generated successfully!",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'todo_report.pdf');
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to generate report: $e",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "Todo App",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.indigo,
          elevation: 5,
          actions: [
            IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Colors.white,),
              onPressed: generatePdfReport,
            ),
          ],
        ),
        backgroundColor: Colors.lightBlue[50],
        body: Column(
          children: [
            SizedBox(height: 35),
            Row(
              children: [
                SizedBox(width: 20),
                Expanded(
                  child: Container(
                    height: 50,
                    child: TextField(
                      controller: itemController,
                      decoration: InputDecoration(
                        labelText: "Enter Item",
                        labelStyle: TextStyle(color: Colors.indigo),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.indigo),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: AddDataIntoList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                  child: Text(
                    "Add",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  color: Colors.indigo,
                  height: 1,
                  width: 100,
                ),
                Text(
                  "   Todo List   ",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  color: Colors.indigo,
                  height: 1,
                  width: 100,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: itemList.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        itemList[index]["task"],
                        style: TextStyle(
                          fontSize: 18,
                          decoration: itemList[index]["isChecked"]
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      leading: Checkbox(
                        value: itemList[index]["isChecked"],
                        onChanged: (bool? value) {
                          setState(() {
                            itemList[index]["isChecked"] = value!;
                            updateTask(itemList[index]["id"], value);
                          });
                        },
                        activeColor: Colors.indigo,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () => deleteTask(itemList[index]["id"]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
