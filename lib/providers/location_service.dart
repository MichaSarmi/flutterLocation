import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:http/http.dart'as http;
import 'package:my_app/models/location.dart';


class LocationService extends ChangeNotifier{
  final baseUrl = 'flutter-varios-2d50d-default-rtdb.firebaseio.com';

  //para lleer el token
    final storage = const FlutterSecureStorage();

    bool isLoading = true;
  bool isSaving = false;

  //cear producto

  Future createLocation(Location location) async{

    final url = Uri.https(baseUrl,'locations.json',{
      'auth': await storage.read(key: 'token') ?? ''
    });

    final resp  = await http.post(url, body: location.toJson());
    resp;
    final decodeData =  json.decode(resp.body) ;
    if(resp.statusCode != 200 && resp.statusCode !=201 ){
        print('algo salio mal desde el provider');

      }
    return decodeData;
    //

  }

  


  

}