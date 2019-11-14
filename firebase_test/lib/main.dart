import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class List extends StatefulWidget {
  @override
  _MyList createState() => _MyList();
}

class _MyList extends State<List> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("リスト画面"),
      ),
      body: _getData(),
    );
  }

  Widget _getData(){
    return Padding(
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
                document['staff']),
            subtitle: Text('期限 ： ' + document["date"].toString()/*.substring(0, 10)*/ +
                //DateTime.fromMillisecondsSinceEpoch(document['date']).toString() + TimeStampからDateTimeへの変換
                " \n相手 ： " + document['user']),
          ),
        ],
      ),
    );
  }
}
