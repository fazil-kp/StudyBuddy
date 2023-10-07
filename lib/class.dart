import 'package:flutter/material.dart';
class Event {
  String title;
  bool isStudied;

  Event({required this.title, this.isStudied = false});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isStudied': isStudied,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'],
      isStudied: json['isStudied'],
    );
  }
}
