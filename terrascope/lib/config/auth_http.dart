import 'package:http/http.dart' as http_base;
import 'dart:convert';
import 'auth_client.dart';

final AuthClient _client = AuthClient();

Future<http_base.Response> get(Uri url, {Map<String, String>? headers}) => 
  _client.get(url, headers: headers);

Future<http_base.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => 
  _client.post(url, headers: headers, body: body, encoding: encoding);

Future<http_base.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => 
  _client.put(url, headers: headers, body: body, encoding: encoding);

Future<http_base.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => 
  _client.patch(url, headers: headers, body: body, encoding: encoding);

Future<http_base.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => 
  _client.delete(url, headers: headers, body: body, encoding: encoding);
