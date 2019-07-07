import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(
      home: TelaPrincipal(),
      title: "Tarefas", // esse título não é visível na aplicação
      debugShowCheckedModeBanner: false,
    ));

class TelaPrincipal extends StatefulWidget {
  @override
  _TelaPrincipalState createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  List _minhasTarefas = [];
  final _minhasTarefasController = TextEditingController();
  Map<String, dynamic> _ultimoRemovido;
  int _ultimoRemovidoPsicao;

  // sobrescrevo esse metodo para a aplicação conseguir buscar os dados salvos localmente e apresentar na tela
  @override
  void initState() {
    super.initState();
    _lerDados().then((dado) {
      setState(() {
        _minhasTarefas = jsonDecode(dado);
      });
    });
  }

  void _addTarefa() {
    setState(() {
      Map<String, dynamic> novaTarefa = Map();
      novaTarefa["title"] = _minhasTarefasController.text;
      _minhasTarefasController.text = "";
      novaTarefa["ok"] = false;
      _minhasTarefas.add(novaTarefa);
      _salvarTarefas();
    });
  }

  Future<Null> _ordenar() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _minhasTarefas.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _salvarTarefas();
    });
  }

  Future<File> _getArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File("${diretorio.path}/data.json");
  }

  // pega a lista transforma em json e salva em dado
  Future<File> _salvarTarefas() async {
    String dado = json.encode(_minhasTarefas);
    final arquivo = await _getArquivo();
    return arquivo.writeAsString(dado);
  }

  Future<String> _lerDados() async {
    try {
      final arquivo = await _getArquivo();
      return arquivo.readAsString();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tarefas"),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: Container(
          decoration: new BoxDecoration(
            gradient: new LinearGradient(colors: [const Color(0xFF00c3ff),const Color(0xFFffff1c)],
                begin: FractionalOffset.topLeft,
                end: FractionalOffset.bottomRight,
                //stops: [0.0,1.0],
               // tileMode: TileMode.clamp
            ),
          ),
          child:  Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _minhasTarefasController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.redAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.redAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addTarefa,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _ordenar,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _minhasTarefas.length,
                itemBuilder: construirItem),
          ))
        ],
      ),
        ),
      
      
      
      
      
      
    );
  }

  // função que desenha cada item na tela
  Widget construirItem(BuildContext context, int index) {
    return Dismissible(
      //É necessario uma key, para identificar qual item da lista  dverá ser excluído, e deverá ser diferente para cada item
      // key, vai receber o tempo atual em milissegundos, poderia ser um randon
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_minhasTarefas[index]["title"]),
        value: _minhasTarefas[index]
            ["ok"], // verifica se o checkbox esta clicado ou nao
        secondary: CircleAvatar(
            child:
                Icon(_minhasTarefas[index]["ok"] ? Icons.check : Icons.error)),
        //secondary para colocar icone do lado da palavra na lista
        onChanged: (c) {
          setState(() {
            _minhasTarefas[index]["ok"] = c;
            _salvarTarefas();
          });
        },
      ),
      // servirá, para caso eu queira desfazer uma exclusão
      onDismissed: (direcao) {
        setState(() {
          _ultimoRemovido = Map.from(_minhasTarefas[index]);
          _ultimoRemovidoPsicao = index;
          _minhasTarefas.removeAt(index);
          _salvarTarefas();

          final snack = SnackBar(
            content: Text("Tarefa \"${_ultimoRemovido["title"]}\" removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _minhasTarefas.insert(
                        _ultimoRemovidoPsicao, _ultimoRemovido);
                    _salvarTarefas();
                  });
                }),
            duration: Duration(seconds: 2), //Duração do snack na tela
          );
          Scaffold.of(context).removeCurrentSnackBar(); //Removermos a Snackbar atual antes de mostrarmos a nova. Assim elas não irão ser empilhadas!
          Scaffold.of(context)
              .showSnackBar(snack); // Responsável por exibir na tela
        });
      },
    );
  }
}
