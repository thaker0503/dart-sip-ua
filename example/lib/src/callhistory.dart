import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';

class CallHistoryPage extends StatefulWidget {
  final SharedPreferences? preferences;
  final SIPUAHelper? helper;
  final Function? handleSelectedNumber;
  final bool? isWideScreen;

  const CallHistoryPage({
    Key? key,
    this.preferences,
    required this.helper,
    required this.handleSelectedNumber,
    required this.isWideScreen,
  }) : super(key: key);

  @override
  _CallHistoryPageState createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage>
    with SingleTickerProviderStateMixin {
  List<CallHistoryEntry> _callHistoryData = [];
  List<CallHistoryEntry> _filteredCallHistoryData = [];
  final String _callHistoryKey = 'callLogs';
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _getCallHistoryData();
    _tabController = TabController(vsync: this, length: 3);
    _tabController!.addListener(_handleTabSelection);
  }

  void _getCallHistoryData() async {
    final prefs = await SharedPreferences.getInstance();
    final callHistoryJson = prefs.getStringList(_callHistoryKey) ?? [];
    List<CallHistoryEntry> loadedData = callHistoryJson.map((entryJson) {
      final entryMap = jsonDecode(entryJson);
      return CallHistoryEntry(
        type: entryMap['type'],
        info: entryMap['info'],
        timestamp: DateTime.parse(entryMap['timestamp']),
      );
    }).toList();
    setState(() {
      _callHistoryData = loadedData;
      _filteredCallHistoryData = loadedData; // Initially show all history
    });
  }

  void _handleTabSelection() {
    setState(() {
      switch (_tabController!.index) {
        case 0:
          _filteredCallHistoryData = _callHistoryData;
          break;
        case 1:
          _filteredCallHistoryData = _callHistoryData
              .where((entry) => entry.type == 'Outgoing')
              .toList();
          break;
        case 2:
          _filteredCallHistoryData = _callHistoryData
              .where((entry) => entry.type == 'Incoming')
              .toList();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Call History'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'All'),
              Tab(text: 'Outgoing'),
              Tab(text: 'Incoming'),
            ],
          ),
        ),
        body: Container(
          color: Color.fromARGB(255, 26, 26, 26),
          child: _filteredCallHistoryData.isEmpty
              ? _emptyState()
              : ListView.builder(
                  itemCount: _filteredCallHistoryData.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredCallHistoryData[index];
                    return _callHistoryListItem(entry);
                  },
                ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text('No call history', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _callHistoryListItem(CallHistoryEntry entry) {
    IconData callIcon =
        entry.type == 'Outgoing' ? Icons.call_made : Icons.call_received;
    return GestureDetector(
      onTap: () {
        widget.handleSelectedNumber!(entry.info);
        if (!widget.isWideScreen!) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey),
          ),
        ),
        child: Row(
          children: [
            Icon(callIcon, color: Colors.white),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.info, style: TextStyle(color: Colors.white)),
                Text(
                  DateFormat('EEE, MMM d, h:mm a').format(entry.timestamp),
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CallHistoryEntry {
  final String type;
  final String info;
  final DateTime timestamp;

  CallHistoryEntry({
    required this.type,
    required this.info,
    required this.timestamp,
  });
}
