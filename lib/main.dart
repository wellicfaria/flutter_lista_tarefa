import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];

  final textEditingController = TextEditingController();

  Map<String, dynamic> _lastRemovedTodo;
  int _positionLastRemovedTodo;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _savaData();
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = textEditingController.text;
      newTodo["ok"] = false;
      _toDoList.add(newTodo);
      _savaData();
    });
  }

  Widget buildItem(context, index) {
    return Dismissible(
        onDismissed: (direcao) {
          setState(() {
            _lastRemovedTodo = Map.from(_toDoList[index]);
            _positionLastRemovedTodo = index;
            _toDoList.removeAt(index);
            _savaData();
          });

          final snackbar = SnackBar(
              duration: Duration(seconds: 2),
              content: Text('Tarefa ${_lastRemovedTodo['title']} removida.'),
              action: SnackBarAction(
                label: 'Desfazer!',
                onPressed: () {
                  setState(() {
                    _toDoList.insert(
                        _positionLastRemovedTodo, _lastRemovedTodo);
                    _savaData();
                  });
                },
              ));
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snackbar);
        },
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        background: Container(
            color: Colors.red,
            child: Align(
                alignment: Alignment(-0.9, 0.0),
                child: Icon(Icons.delete, color: Colors.white))),
        direction: DismissDirection.startToEnd,
        child: CheckboxListTile(
            value: _toDoList[index]["ok"],
            title: Text(_toDoList[index]["title"]),
            onChanged: (c) {
              setState(() {
                _toDoList[index]["ok"] = c;
                _savaData();
              });
            },
            secondary: CircleAvatar(
                child:
                    Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                        controller: textEditingController,
                        decoration: InputDecoration(
                            labelText: "Nova tarefa",
                            labelStyle: TextStyle(color: Colors.blueAccent)))),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem),
          ))
        ],
      ),
    );
  }

  Future<File> _getFile() async {
    final diretory = await getApplicationDocumentsDirectory();

    return File("${diretory.path}/data.json");
  }

  Future<File> _savaData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
