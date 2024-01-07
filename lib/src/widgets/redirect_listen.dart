import 'dart:io';

import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/variables.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _redirectHost = 'localhost';
const _redirectPort = 46837;
const redirectUri = 'http://$_redirectHost:$_redirectPort';

class RedirectListener extends StatefulWidget {
  final Uri initUri;
  final String title;

  const RedirectListener(this.initUri, {super.key, this.title = ''});

  @override
  State<RedirectListener> createState() => _RedirectListenerState();
}

class _RedirectListenerState extends State<RedirectListener> {
  Future<Uri> _listenForAuth() async {
    HttpServer server = await HttpServer.bind(_redirectHost, _redirectPort);
    launchUrl(widget.initUri);
    final req = await server.first;
    final result = req.uri;
    req.response.statusCode = 200;
    req.response.headers.set("content-type", "text/plain");
    req.response.writeln(
        "Redirect received. You can close this tab now and return to the app.");
    await req.response.close();
    await server.close();
    return result;
  }

  @override
  void initState() {
    if (!isWebViewSupported) {
      _listenForAuth()
          .then((value) => Navigator.pop(context, value.queryParameters));
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isWebViewSupported) {
      var controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith(redirectUri)) {
                WebViewCookieManager().clearCookies();
                Navigator.pop(context, Uri.parse(request.url).queryParameters);
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(widget.initUri);

      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: WebViewWidget(controller: controller),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: const Center(child: Text('Continue in browser')),
    );
  }
}
