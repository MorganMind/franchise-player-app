import 'package:flutter/material.dart';

class ChannelSidebar extends StatefulWidget {
  final String serverId;
  final String? currentFranchiseId;
  final String? currentChannelId;
  final String? currentSubcategoryId;
  final void Function(String? franchiseId, String? channelId, String? subcategoryId)? onSelect;

  const ChannelSidebar({
    Key? key,
    required this.serverId,
    this.currentFranchiseId,
    this.currentChannelId,
    this.currentSubcategoryId,
    this.onSelect,
  }) : super(key: key);

  @override
  State<ChannelSidebar> createState() => _ChannelSidebarState();
}

class _ChannelSidebarState extends State<ChannelSidebar> {
  String? expandedFranchiseId;
  String? expandedChannelId;

  // Example Madden franchise sidebar structure
  final List<Map<String, dynamic>> textChannels = [
    {'id': 'general', 'name': 'general', 'icon': Icons.chat},
    {'id': 'rules', 'name': 'rules', 'icon': Icons.gavel},
    {'id': 'announcements', 'name': 'announcements', 'icon': Icons.announcement},
    {'id': 'help', 'name': 'help', 'icon': Icons.help},
  ];

  final List<Map<String, dynamic>> franchises = [
    {
      'id': 'f1',
      'name': 'Madden X Launch',
      'channels': [
        {'id': 'general', 'name': 'General'},
        {
          'id': 'trades',
          'name': 'Trades',
          'subcategories': [
            {'id': 'completed', 'name': 'Completed Trades'},
            {'id': 'pending', 'name': 'Pending Trades'},
          ]
        },
        {
          'id': 'gotw',
          'name': 'Game of the Week',
          'subcategories': [
            {'id': 'highlights', 'name': 'Highlights'},
            {'id': 'predictions', 'name': 'Predictions'},
          ]
        },
        {'id': 'schedule', 'name': 'Schedule'},
        {'id': 'rosters', 'name': 'Players'},
        {'id': 'stats', 'name': 'Stats'},
        {'id': 'awards', 'name': 'Awards'},
      ]
    },
    {
      'id': 'f2',
      'name': 'Madden X Reboot',
      'channels': [
        {'id': 'general', 'name': 'General'},
        {'id': 'trades', 'name': 'Trades'},
        {'id': 'schedule', 'name': 'Schedule'},
      ]
    },
    {
      'id': 'f3',
      'name': 'Madden X 7 Day Sim',
      'channels': [
        {'id': 'general', 'name': 'General'},
        {'id': 'trades', 'name': 'Trades'},
        {'id': 'schedule', 'name': 'Schedule'},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Color(0xFFF2F3F5),
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader('TEXT CHANNELS'),
          ...textChannels.map((channel) => _buildTextChannel(channel)),
          SizedBox(height: 16),
          _buildSectionHeader('FRANCHISES'),
          ...franchises.map((franchise) => _buildFranchise(franchise)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Color(0xFF6C757D),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextChannel(Map<String, dynamic> channel) {
    final isActive = widget.currentFranchiseId == null && widget.currentChannelId == channel['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          if (widget.onSelect != null) {
            widget.onSelect!(null, channel['id'], null);
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Color(0xFFE9ECEF) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.tag, color: Color(0xFF6C757D), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  channel['name'],
                  style: TextStyle(
                    color: isActive ? Colors.black : Color(0xFF6C757D),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFranchise(Map<String, dynamic> franchise) {
    final isExpanded = expandedFranchiseId == franchise['id'];
    final isActive = widget.currentFranchiseId == franchise['id'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              setState(() {
                expandedFranchiseId = isExpanded ? null : franchise['id'];
                expandedChannelId = null;
              });
              if (widget.onSelect != null) {
                widget.onSelect!(franchise['id'], null, null);
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Color(0xFFE9ECEF) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_football, color: Color(0xFF6C757D), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      franchise['name'],
                      style: TextStyle(
                        color: isActive ? Colors.black : Color(0xFF6C757D),
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Color(0xFF6C757D), size: 18),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List<Map<String, dynamic>>.from(franchise['channels']).map((channel) => _buildChannel(franchise['id'], channel)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChannel(String franchiseId, Map<String, dynamic> channel) {
    final isExpanded = expandedChannelId == channel['id'];
    final isActive = widget.currentFranchiseId == franchiseId && widget.currentChannelId == channel['id'] && widget.currentSubcategoryId == null;
    final hasSubcategories = channel['subcategories'] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              if (hasSubcategories) {
                setState(() {
                  expandedChannelId = isExpanded ? null : channel['id'];
                });
              }
              if (widget.onSelect != null) {
                widget.onSelect!(franchiseId, channel['id'], null);
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Color(0xFFD1E7DD) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Color(0xFF6C757D), size: 15),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      channel['name'],
                      style: TextStyle(
                        color: isActive ? Colors.black : Color(0xFF6C757D),
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (hasSubcategories)
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Color(0xFF6C757D), size: 16),
                ],
              ),
            ),
          ),
        ),
        if (hasSubcategories && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List<Map<String, dynamic>>.from(channel['subcategories']).map((subcat) => _buildSubcategory(franchiseId, channel['id'], subcat)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubcategory(String franchiseId, String channelId, Map<String, dynamic> subcat) {
    final isActive = widget.currentFranchiseId == franchiseId && widget.currentChannelId == channelId && widget.currentSubcategoryId == subcat['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          if (widget.onSelect != null) {
            widget.onSelect!(franchiseId, channelId, subcat['id']);
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Color(0xFFB6E0FE) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, color: Color(0xFF6C757D), size: 9),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  subcat['name'],
                  style: TextStyle(
                    color: isActive ? Colors.black : Color(0xFF6C757D),
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 