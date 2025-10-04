import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/franchise_providers.dart';
import '../../../../models/franchise.dart';
import '../../../../supabase_client.dart';

class FranchiseFinderPage extends ConsumerStatefulWidget {
  const FranchiseFinderPage({super.key});

  @override
  ConsumerState<FranchiseFinderPage> createState() => _FranchiseFinderPageState();
}

class _FranchiseFinderPageState extends ConsumerState<FranchiseFinderPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedServerFilter = 'all';
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Franchise Finder'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allFranchisesProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilterBar(),
          
          // Franchise List
          Expanded(
            child: _buildFranchiseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search franchises...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filters Row
          Row(
            children: [
              // Server Filter
              Expanded(
                child: _buildServerFilter(),
              ),
              const SizedBox(width: 12),
              // Sort Options
              Expanded(
                child: _buildSortOptions(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerFilter() {
    return Consumer(
      builder: (context, ref, child) {
        final serversAsync = ref.watch(allServersProvider);
        
        return serversAsync.when(
          data: (servers) {
            final serverOptions = [
              {'id': 'all', 'name': 'All Servers'},
              ...servers.map((server) => {
                'id': server['id'] as String,
                'name': (server['name'] as String?) ?? 'Unknown Server',
              }).toList(),
            ];

            return DropdownButtonFormField<String>(
              value: _selectedServerFilter,
              decoration: InputDecoration(
                labelText: 'Server',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: serverOptions.map((server) {
                return DropdownMenuItem(
                  value: server['id'],
                  child: Text(
                    server['name']!,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedServerFilter = value!;
                });
              },
            );
          },
          loading: () => DropdownButtonFormField<String>(
            value: 'all',
            decoration: const InputDecoration(
              labelText: 'Server',
              border: OutlineInputBorder(),
            ),
            items: const [DropdownMenuItem(value: 'all', child: Text('Loading...'))],
            onChanged: null,
          ),
          error: (error, stack) => DropdownButtonFormField<String>(
            value: 'all',
            decoration: const InputDecoration(
              labelText: 'Server',
              border: OutlineInputBorder(),
            ),
            items: const [DropdownMenuItem(value: 'all', child: Text('Error loading servers'))],
            onChanged: null,
          ),
        );
      },
    );
  }

  Widget _buildSortOptions() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _sortBy,
            decoration: InputDecoration(
              labelText: 'Sort by',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'name', child: Text('Name')),
              DropdownMenuItem(value: 'created_at', child: Text('Created')),
              DropdownMenuItem(value: 'updated_at', child: Text('Updated')),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            setState(() {
              _sortAscending = !_sortAscending;
            });
          },
          icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
          tooltip: _sortAscending ? 'Sort ascending' : 'Sort descending',
        ),
      ],
    );
  }

  Widget _buildFranchiseList() {
    return Consumer(
      builder: (context, ref, child) {
        final franchisesAsync = ref.watch(allFranchisesProvider);
        
        return franchisesAsync.when(
          data: (allFranchises) {
            // Apply filters and search
            final filteredFranchises = _filterAndSortFranchises(allFranchises);
            
            if (filteredFranchises.isEmpty) {
              return _buildEmptyState();
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredFranchises.length,
              itemBuilder: (context, index) {
                final franchise = filteredFranchises[index];
                return _buildFranchiseCard(franchise);
              },
            );
          },
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading franchises...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading franchises',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(allFranchisesProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Franchise> _filterAndSortFranchises(List<Franchise> franchises) {
    // Apply search filter
    List<Franchise> filtered = franchises.where((franchise) {
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      return franchise.name.toLowerCase().contains(query) ||
             (franchise.externalId?.toLowerCase().contains(query) ?? false) ||
             (franchise.metadata?['description']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();

    // Apply server filter
    if (_selectedServerFilter != 'all') {
      filtered = filtered.where((franchise) {
        return franchise.serverId == _selectedServerFilter;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'created_at':
          comparison = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
          break;
        case 'updated_at':
          comparison = (a.updatedAt ?? DateTime.now()).compareTo(b.updatedAt ?? DateTime.now());
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildFranchiseCard(Franchise franchise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openFranchise(franchise),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Franchise Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sports_football,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Franchise Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          franchise.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Franchise',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // External ID if available
                  if (franchise.externalId != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        franchise.externalId!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              // Description if available
              if (franchise.metadata?['description'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  franchise.metadata!['description'].toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Metadata row
              const SizedBox(height: 12),
              Row(
                children: [
                  // Created date
                  if (franchise.createdAt != null) ...[
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Created ${_formatDate(franchise.createdAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Updated date
                  if (franchise.updatedAt != null) ...[
                    Icon(Icons.update, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Updated ${_formatDate(franchise.updatedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_football_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No franchises found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'No franchises match your current filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openFranchise(Franchise franchise) {
    // Navigate to the franchise page
    final franchiseName = franchise.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
    context.go('/franchise/$franchiseName');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

// Provider for all servers
final allServersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return supabase
      .from('servers')
      .stream(primaryKey: ['id'])
      .order('name')
      .map((event) => event.map((json) => Map<String, dynamic>.from(json)).toList());
});
