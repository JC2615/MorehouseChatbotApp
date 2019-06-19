import 'package:flutter/material.dart';
import 'package:googleapis/dialogflow/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
int count = 1;
void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Dialogflow App',
      theme: new ThemeData(
        primarySwatch: Colors.red,
      ),
      home: new ChatMessages(),
    );
  }
}

class ChatMessages extends StatefulWidget {
  @override
  _ChatMessagesState createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages>
    with TickerProviderStateMixin {
  List<ChatMessage> _messages = List<ChatMessage>();
  bool _isComposing = false;

  TextEditingController _controllerText = new TextEditingController();

  DialogflowApi _dialog;

  @override
  void initState() {
    super.initState();
    _initChatbot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(title: new Text("Morehouse Chatbot"), backgroundColor: Colors.red[900],),
        body: Column(
          children: <Widget>[
            _buildList(),
            Divider(height: 8.0, color: Colors.red[900]),
            _buildComposer()
          ],
        ));
  }

  _buildList() {
    return Flexible(
      child: ListView.builder(
          padding: EdgeInsets.all(8.0),
          reverse: true,
          itemCount: _messages.length,
          itemBuilder: (_, index) {
            return Container(child: ChatMessageListItem(_messages[index]));
          }),
    );
  }

  _buildComposer() {
    return Container(
      margin: EdgeInsets.only(bottom: 5, left: 20, right: 20, top: 0), //height: 100,
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: _controllerText,
              onChanged: (value) {
                setState(() {
                  _isComposing = _controllerText.text.length > 0;
                });
              },
              onSubmitted: _handleSubmit,
              decoration: InputDecoration.collapsed(hintText: "Enter question..."),
            ),
          ),
          new IconButton(
            alignment: Alignment.centerRight,
            icon: Icon(Icons.send),
            onPressed:
            _isComposing ? () => _handleSubmit(_controllerText.text) : null,
          ),
        ],
      ),
    );
  }

  _handleSubmit(String value) {
    _controllerText.clear();
    if (value.trim().isNotEmpty) {
     _addMessage(
      text: value,
      name: "User",
      initials: "U",
      ); 

      _requestChatBot(value);
    }
  }

  _requestChatBot(String text) async {
    var dialogSessionId = "projects/morehouse-5b1fa/agent/sessions/169808355983";

    Map data = {
      "queryInput": {
        "text": {
          "text": text,
          "languageCode": "en",
        }
      }
    };

    var request = GoogleCloudDialogflowV2DetectIntentRequest.fromJson(data);

    var resp = await _dialog.projects.agent.sessions
        .detectIntent(request, dialogSessionId);
    var result = resp.queryResult;
    _addMessage(
        name: "Morehouse Chatbot",
        initials: "MC",
        bot: true,
        text: result.fulfillmentText);
  }

  void _initChatbot() async {
    String configString = await rootBundle.loadString('config/dialogflow.json');
    String _dialogFlowConfig = configString;

    var credentials = new ServiceAccountCredentials.fromJson(_dialogFlowConfig);

    const _SCOPES = const [DialogflowApi.CloudPlatformScope];

    var httpClient = await clientViaServiceAccount(credentials, _SCOPES);
    _dialog = new DialogflowApi(httpClient);
  }

  void _addMessage(
      {String name, String initials, bool bot = false, String text}) {
    var animationController = AnimationController(
      duration: new Duration(seconds: 1),
      vsync: this,
    );

    var message = ChatMessage(
        name: name,
        text: text,
        initials: initials,
        bot: bot,
        animationController: animationController);

    setState(() {
      _messages.insert(0, message);
    });
    count++;
    animationController.forward();
  }
  
}

class ChatMessage {
  final String name;
  final String initials;
  final String text;
  final bool bot;

  AnimationController animationController;

  ChatMessage(
      {this.name,
        this.initials,
        this.text,
        this.bot = false,
        this.animationController});
}

class ChatMessageListItem extends StatelessWidget {
  final ChatMessage chatMessage;
  ChatMessageListItem(this.chatMessage);
  

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    var time =  new DateFormat.jm().format(now); 
    CircleAvatar mh = CircleAvatar(
                backgroundImage: AssetImage('config/morehouse.png'),
                backgroundColor: chatMessage.bot
                    ? Colors.white
                    : Colors.white,
              );
    CircleAvatar user = CircleAvatar(
                child: Text(chatMessage.initials),
                backgroundColor: chatMessage.bot
                    ? Colors.red[900]
                    : Colors.red[900],
              );

    CircleAvatar circ;
      Container messageBox;

      if(chatMessage.bot){
        circ = mh;
      }
      else{
        circ  = user;
      }

      Container mhBox = Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Flexible(
              child: Container(
                margin: EdgeInsets.only(right: 16.0),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text('${chatMessage.name}',
                        style: Theme.of(context).textTheme.subhead, textAlign: TextAlign.right,),
                    Text('$time',
                        style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold)),
                    Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: Text(chatMessage.text, textAlign: TextAlign.right,)
                    )
                  ],
                ))
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: circ,
            )
          ],
        ),
      );

      Container userBox = Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: circ,
            ),
            Flexible(
              child: Container(
                margin: EdgeInsets.only(left: 16.0),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${chatMessage.name}',
                        style: Theme.of(context).textTheme.subhead, textAlign: TextAlign.right,),
                    Text('$time',
                        style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold)),
                    Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: Text(chatMessage.text)
                    )
                  ],
                ))
            )
          ],
        ),
      );
      
      if(chatMessage.bot){
        messageBox = mhBox;
      }
      else{
        messageBox  = userBox;
      }
    
      return SizeTransition(
      sizeFactor: CurvedAnimation(
          parent: chatMessage.animationController, curve: Curves.easeOut),
      child: messageBox
    );

    
  }
}
