import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';//非同期処理のため

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '貸し借りメモ',
      home: List(),
    );
  }
}

class InputForm extends StatefulWidget {
  @override
  _MyInputFormState createState() => _MyInputFormState();
}

//入力する変数を管理
class _FormData {
  String info = "borrow";
  String user;
  String stuff;
  DateTime date = DateTime.now();
}

class _MyInputFormState extends State<InputForm>{

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _FormData _data = _FormData();

  //非同期処理
  Future<DateTime> _selectTime(BuildContext context){
    return showDatePicker(
        context: context,
        initialDate: _data.date,//初期の日付
        firstDate: DateTime(_data.date.year - 2),//2年前
        lastDate: DateTime(_data.date.year + 2)//2年後
    );
  }

  //貸した、借りたボタン情報をセットする
  void _setLendOrRent(String value){
    setState(() {
      _data.info = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference _mainReference;
    _mainReference = Firestore.instance.collection('borrow_info').document();//インスタンスを生成

    return Scaffold(
      appBar: AppBar(
        title: Text("貸し借り入力"),
        actions: <Widget>[
          //保存、削除ボタンを表示
          IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                print("保存完了");
                if (_formKey.currentState.validate()) {//エラー文表示のためのvalidate()を呼び出す
                  _formKey.currentState.save();//名前、状態のonSave()を呼び出す
                  //Cloud Firestore へのデータ登録
                  _mainReference.setData(
                      {
                        'info': _data.info,
                        'user': _data.user,
                        'stuff': _data.stuff,
                        'date': _data.date,
                      }
                  );
                  Navigator.pop(context);//元の画面に戻る
                }
              }
          ),
          IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                print("削除完了");
              }
          ),
        ],
      ),
      body: SafeArea(
        child:
        //データ入力の作成
        Form(
            key: _formKey,//フォーム全体に対する制御を行う。入力チェックに利用
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: <Widget>[
                //ラジオボタンの作成（丸いやつ◉　◎　こんなの）
                RadioListTile(
                    value: "borrow",
                    groupValue: _data.info,
                    title: Text("借りた"),
                    onChanged: (String value) {
                      print("借りたをタッチ");
                      _setLendOrRent(value);
                    }
                ),
                RadioListTile(
                    value: "lend",
                    groupValue: _data.info,
                    title: Text("貸した"),
                    onChanged: (String value) {
                      print("貸したをタッチ");
                      _setLendOrRent(value);
                    }
                ),
                //テキストの入力フィールド
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.person),
                    hintText: '相手の名前',
                    labelText: 'Name',
                  ),
                  onSaved: (String value) {//値の代入
                    _data.user = value;
                  },
                  validator: (value) {//空欄時にエラー文を表示
                    if (value.isEmpty) {
                      return '名前は入力必須です';
                    }
                  },
                  initialValue: _data.user,//初期値の設定
                ),

                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.business_center),
                    hintText: '借りたもの、貸したもの',
                    labelText: 'Ioan',
                  ),
                  onSaved: (String value) {//値の代入
                    _data.stuff = value;
                  },
                  validator: (value) {//空欄時にエラー文を表示
                    if (value.isEmpty) {
                      return '借りたもの、貸したものは入力必須です';
                    }
                  },
                  initialValue: _data.stuff,//初期値の設定
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                      child: Text("締め切り日：${_data.date.toString().substring(0,10)}"),
                ),

                RaisedButton(
                  child: const Text("締め切り日変更"),
                    onPressed: (){
                      print("締め切り日変更をタッチ");
                      _selectTime(context).then((time){
                        if (time != null && time != _data.date){
                          setState(() {
                            _data.date = time;
                          });
                        }
                      });
                    },
                    ),
                ],
              )
          ),
      ),
    );
  }
}

class List extends StatefulWidget {
  @override
  _MyList createState() => _MyList();
}

class _MyList extends State<List> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("リスト"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>( //Cloud Firestoreからデータを取得し、表示させる
            stream: Firestore.instance.collection('borrow_info').snapshots(), //非同期で所得できるデータ
            builder: //streamに変化が会った時に呼び出される
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return const Text('Loading...');//データローディング時
              return ListView.builder(
                itemCount: snapshot.data.documents.length,
                padding: const EdgeInsets.only(top: 10.0),
                itemBuilder: (context, index) =>
                    _buildListItem(context, snapshot.data.documents[index]),
              );
            }),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            print("新規作成ボタンを押しました");
            Navigator.push(
              context,
              MaterialPageRoute(
                  settings: const RouteSettings(name: "/new"),
                  builder: (BuildContext context) => InputForm()
              ),
            );
          }
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.android),
            title: Text("【 " +
                (document['info'] == "lend" ? "貸" : "借") +
                " 】" +
                document['stuff']),
            subtitle: Text('期限 ： ' + document["date"].toString()/*.substring(0, 10)*/ +
                //DateTime.fromMillisecondsSinceEpoch(document['date']).toString() + TimeStampからDateTimeへの変換
                " \n相手 ： " + document['user']),
          ),
          ButtonTheme.bar(
            child: ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: const Text("編集"),
                  onPressed: () {
                    print("編集ボタンを押しました");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
