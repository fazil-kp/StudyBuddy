import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'class.dart';

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
    _loadSavedEvents();
    super.initState();
  }

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
        backgroundColor: Colors.indigo, // Set the app bar background color
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.indigo[100],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TableCalendar(
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
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.purpleAccent,
                    shape: BoxShape.circle,
                  ),
                  defaultDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  weekendDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: Colors.white,
                  ),
                ),
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
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      elevation: 3.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          title: Text(
                            event.title,
                            style: TextStyle(fontSize: 18.0),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                  _editEventController.text = event.title;
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("Edit Subject"),
                                      content: TextFormField(
                                        controller: _editEventController,
                                        decoration: InputDecoration(
                                          labelText: "Edit event",
                                        ),
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
                                  setState(() {
                                    selectedEvents[selectedDay]!.remove(event);
                                    _saveEventsToStorage();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
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
              content: Container(
                decoration: BoxDecoration(
                  color: Colors.indigo[200],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: TextFormField(
                  controller: _eventController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.subject),
                    labelText: "Enter subject",labelStyle: TextStyle(fontWeight: FontWeight.bold)
                  ),
                ),
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
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
