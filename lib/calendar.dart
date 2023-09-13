import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class Calendar extends StatefulWidget {
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late Map<DateTime, List<Event>> selectedEvents;
  CalendarFormat format = CalendarFormat.month;
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  TextEditingController _eventController = TextEditingController();
  TextEditingController _editEventController = TextEditingController();

  @override
  void initState() {
    selectedEvents = {};
    _loadSavedEvents(); // Load events from SharedPreferences
    super.initState();
  }

  // Load saved events from SharedPreferences
  Future<void> _loadSavedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      final Map<String, dynamic> eventsMap = jsonDecode(eventsJson);
      selectedEvents = eventsMap.map((key, value) {
        return MapEntry(
          DateTime.parse(key),
          (value as List).map((e) => Event.fromJson(e)).toList(),
        );
      });
      setState(() {});
    }
  }

  // Save events to SharedPreferences
  Future<void> _saveEventsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = jsonEncode(
      selectedEvents.map((key, value) {
        return MapEntry(
          key.toString(),
          value.map((e) => e.toJson()).toList(),
        );
      }),
    );
    await prefs.setString('events', eventsJson);
  }

  List<Event> _getEventsforDay(DateTime date) {
    return selectedEvents[date] ?? [];
  }

  @override
  void dispose() {
    _eventController.dispose();
    _editEventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("StudyBuddy"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: selectedDay,
            firstDay: DateTime(1990),
            lastDay: DateTime(2050),
            calendarFormat: format,
            onFormatChanged: (CalendarFormat _format) {
              setState(() {
                format = _format;
              });
            },
            startingDayOfWeek: StartingDayOfWeek.sunday,
            daysOfWeekVisible: true,
            onDaySelected: (DateTime selectDay, DateTime focusDay) {
              setState(() {
                selectedDay = selectDay;
                focusedDay = focusDay;
              });
            },
            selectedDayPredicate: (DateTime date) {
              return isSameDay(selectedDay, date);
            },
            eventLoader: _getEventsforDay,
            calendarStyle: CalendarStyle(
              isTodayHighlighted: true,
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0),
              ),
              selectedTextStyle: TextStyle(color: Colors.white),
              todayDecoration: BoxDecoration(
                color: Colors.purpleAccent,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0),
              ),
              defaultDecoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0),
              ),
              weekendDecoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(5.0),
              ),
              formatButtonTextStyle: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ..._getEventsforDay(selectedDay).asMap().entries.map(
                      (entry) {
                    final int index = entry.key;
                    final Event event = entry.value;
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              event.isStudied ? Icons.check_circle : Icons.circle,
                              color: event.isStudied ? Colors.green : Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                event.isStudied = !event.isStudied;
                                _saveEventsToStorage();
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              // Open an edit event dialog
                              _editEventController.text = event.title;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Edit Subject"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        controller: _editEventController,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text("Cancel"),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                    TextButton(
                                      child: Text("Save"),
                                      onPressed: () {
                                        // Handle save edit event action here
                                        setState(() {
                                          event.title = _editEventController.text;
                                          _saveEventsToStorage();
                                          Navigator.pop(context);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              // Handle delete event action here
                              setState(() {
                                selectedEvents[selectedDay]!.remove(event);
                                _saveEventsToStorage();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Add Subject"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _eventController,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text("Ok"),
                  onPressed: () {
                    if (_eventController.text.isNotEmpty) {
                      final newEvent = Event(
                        title: _eventController.text,
                        isStudied: false,
                      );
                      if (selectedEvents[selectedDay] != null) {
                        selectedEvents[selectedDay]!.add(newEvent);
                      } else {
                        selectedEvents[selectedDay] = [newEvent];
                      }

                      _eventController.clear();
                      Navigator.pop(context);
                      setState(() {
                        _saveEventsToStorage();
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
        label: Text("Add Subject"),
        icon: Icon(Icons.add),
      ),
    );
  }
}

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
