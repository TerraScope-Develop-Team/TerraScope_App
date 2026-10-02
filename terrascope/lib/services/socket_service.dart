import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:terrascope/config/api_config.dart';
import 'package:terrascope/services/session_service.dart';
import 'dart:ui';
import 'dart:convert';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  
  IO.Socket? _socket;
  void Function(String title, String body)? _currentOnAlert;
  
  SocketService._internal();

  Future<void> initSocket({void Function(String title, String body)? onAlert}) async {
    if (onAlert != null) {
      _currentOnAlert = onAlert;
    }
    
    if (_socket != null && _socket!.connected) return;
    
    // Obtener userId si existe
    final sessionData = await SessionService().getUserData();
    final userId = sessionData?['_id'];

    // Convertir http://ip:3000/api -> http://ip:3000
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');

    _socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Conectado a Socket.IO');
      if (userId != null) {
        _socket!.emit('join', userId);
      }
    });

    _socket!.on('nuevaAlertaPeligro', (data) {
      print('Nueva alerta de peligro recibida: $data');
      if (_currentOnAlert != null) {
        _currentOnAlert!(
          '¡Alerta de Fauna Peligrosa!', 
          'Se ha reportado la especie ${data['especie']} cerca de tu ubicación.'
        );
      }
    });

    _socket!.onDisconnect((_) => print('Desconectado de Socket.IO'));
  }

  void disconnect() {
    _socket?.disconnect();
  }
}
