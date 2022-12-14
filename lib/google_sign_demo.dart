import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter Firebase")),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text("Google Sign-In Demo"),
            subtitle: const Text("google_sign_in Plugin"),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => GoogleSignInDemo()));
            },
          )
        ].map((child) {
          return Card(
            child: child,
          );
        }).toList(),
      ),
    );
  }
}

GoogleSignInDemoState pageState;

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
  'email',
  'https://www.googleapis.com/auth/contacts.readonly',
]);

class GoogleSignInDemo extends StatefulWidget {
  const GoogleSignInDemo({Key? key}) : super(key: key);

  @override
  GoogleSignInDemoState createState() {
    pageState = GoogleSignInDemoState();
    return pageState;
  }
}

class GoogleSignInDemoState extends State<GoogleSignInDemo> {
  late GoogleSignInAccount _currentUser;
  late String _contactText;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _handleGetContact();
      }
      _googleSignIn.signInSilently();
    });
  }

  Future<void> _handleGetContact() async {
    setState(() {
      _contactText = "Loading contact info...";
    });
    final http.Response response = await http.get(
        'https://people.googleapis.com/v1/people/me/connections'
            '?requestMask.includeField=person.names',
        headers: await _currentUser.authHeaders);

    if (response.statusCode != 200) {
      setState(() {
        _contactText = "People API gave a ${response.statusCode} "
            "response. Check logs for detailes.";
      });
      print("People API ${response.statusCode} response: ${response.body}");
      return;
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final String namedContact = _pickFirstNamedContact(data);
    setState(() {
      if (namedContact != null) {
        _contactText = "I see you know $namedContact";
      } else {
        _contactText = "No contacts to display.";
      }
    });
  }

  String _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic> connections = data['connections'];
    final Map<String, dynamic> contact = connections?.firstWhere(
          (dynamic contact) => contact['names'] != null,
      orElse: () => null,
    );
    if (contact != null) {
      final Map<String, dynamic> name = contact['names'].firstWhere(
            (dynamic name) => name['displayName'] != null,
        orElse: () => null,
      );
      if (name != null) {
        return name['displayName'];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Google Sign-In Demo")),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }

  Widget _buildBody() {
    if (_currentUser != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ListTile(
            leading: GoogleUserCircleAvatar(
              identity: _currentUser,
            ),
            title: Text(_currentUser.displayName ?? ""),
            subtitle: Text(_currentUser.email ?? ""),
          ),
          const Text("Signed in successfully."),
          Text(_contactText ?? ""),
          RaisedButton(
            child: const Text("SIGN OUT"),
            onPressed: _handleSignOut,
          ),
          RaisedButton(
            child: const Text("REFRESH"),
            onPressed: _handleGetContact,
          )
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text("You are not currently signed in"),
          RaisedButton(
            child: const Text("SIGN IN"),
            onPressed: _handleSignIn,
          )
        ],
      );
    }
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() async {
    _googleSignIn.disconnect();
  }
}