// To parse this JSON data, do
//
//     final product = productFromMap(jsonString);

import 'dart:convert';
import 'dart:ffi';

class Location {
    double lat;
    double lon;


    Location({
        required this.lat,
        required this.lon
    });

    

    factory Location.fromJson(String str) => Location.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory Location.fromMap(Map<String, dynamic> json) => Location(
        lon: json["lon"]?.toDouble(),
        lat: json["lat"]?.toDouble(),
    );

    Map<String, dynamic> toMap() => {
        "lon": lon,
        "lat": lat,
    };


   
    
}
