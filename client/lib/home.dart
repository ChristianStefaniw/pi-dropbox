import 'dart:io';

import 'package:client/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'config.dart';

class Home extends StatefulWidget {
  final DB db;
  const Home(this.db);
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File image;
  final picker = ImagePicker();

  Future<void> getImage() async {
    final pickedFile = await this.picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        this.image = File(pickedFile.path);
      }
    });
  }

  Future<void> upload() async {
    String url = await this.widget.db.get('url');
    int port = await this.widget.db.get('port');
    Socket sock = await connectToSocket(url, port);
    List<int> bytes = this.image.readAsBytesSync();

    sock.add(bytes);

    setState(() {
      this.image = null;
    });

    Navigator.pop(context);

    await sock.close();
  }

  Future<Widget> loading() {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return new Center(
          child: new CircularProgressIndicator(),
        );
      },
    );
  }

  Future<Widget> newTcpValues(){
    return showDialog(
      context: context,
      builder: (_){
        TextEditingController urlController = new TextEditingController();
        TextEditingController portController = new TextEditingController();

        return new SimpleDialog(
          children: [
            new TextField(
              decoration: InputDecoration(
                hintText: 'URL',
              ),
              controller: urlController,
            ),
            new TextField(
              decoration: InputDecoration(
                hintText: 'Port',
              ),
              controller: portController,
            ),
            new RaisedButton.icon(
                onPressed: () => write(urlController.text, portController.text),
                icon: Icon(Icons.arrow_circle_down),
                label: Text('Submit'),
            ),
          ],
        );
      }
    );
  }

  void write(String url, String port) async{
    this.widget.db.write('url', url);
    this.widget.db.write('port', port);
    setState((){});
    Navigator.pop(context);
  }

  Future<Widget> success() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return new Dialog(
          child: new Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Text(
              'Success',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: Text("My File Uploader"),
        leading: IconButton(
          icon: Icon(Icons.settings),
          onPressed: this.newTcpValues,
        ),
        actions: [
          IconButton(
              icon: currentTheme.currentTheme() == ThemeMode.dark
                  ? Icon(
                      Icons.lightbulb,
                      color: Theme.of(context).primaryColorLight,
                    )
                  : Icon(
                      Icons.lightbulb,
                      color: Theme.of(context).primaryColorDark,
                    ),
              onPressed: () => currentTheme.switchTheme())
        ],
      ),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                height: MediaQuery.of(context).size.height / 3,
                child: this.image == null ? Text('') : Image.file(this.image)),
            RaisedButton.icon(
              color: Theme.of(context).primaryColorLight,
              onPressed: getImage,
              icon: Icon(Icons.image),
              label: Text('Image'),
            ),
            this.image == null
                ? Container()
                : RaisedButton.icon(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    onPressed: () async {
                      this.loading();
                      await this.upload();
                      this.success();
                    },
                    icon: Icon(Icons.upload_rounded),
                    label: Text('Upload'),
                  ),
            FutureBuilder<dynamic>(
              future: this.widget.db.get('url'),
              builder: (_, AsyncSnapshot<dynamic> snapshot){
                return snapshot.hasData ? Text(snapshot.data) : Container();
              },
            ),
            FutureBuilder<dynamic>(
              future: this.widget.db.get('port'),
              builder: (_, AsyncSnapshot<dynamic> snapshot){
                return snapshot.hasData ? Text(snapshot.data.toString()) : Container();
              },
            ),
          ],
        ),
      ),
    );
  }
}
