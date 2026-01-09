import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/bill_service.dart';
import 'bill_details_screen.dart';

class BillProviderScreen extends StatefulWidget {
  final String billType;

  const BillProviderScreen({super.key, required this.billType});

  @override
  State<BillProviderScreen> createState() => _BillProviderScreenState();
}

class _BillProviderScreenState extends State<BillProviderScreen> {
  final BillService _billService = BillService();
  String searchQuery = '';
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  String? _error;

  // Map bill types to API category values (must match backend BillType enum)
  String get _categoryForBillType {
    switch (widget.billType) {
      case 'Electricity':
        return 'ELECTRICITY';
      case 'Mobile':
        return 'MOBILE';
      case 'Water':
        return 'WATER';
      case 'DTH':
        return 'DSTV';
      default:
        return widget.billType.toUpperCase();
    }
  }

  // Icon for each bill type
  String _getLogoForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'electricity':
        return '⚡';
      case 'mobile':
        return '📱';
      case 'water':
        return '💧';
      case 'dth':
        return '📡';
      default:
        return '��';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _billService.getProviders(category: _categoryForBillType);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          final data = result['data'];
          // API response structure: { success, data: { providers: [...], total } }
          final apiData = data['data'] ?? data;
          final providersList = apiData['providers'] ?? apiData;
          if (providersList is List) {
            _providers = providersList.map((p) => {
              'id': p['id'] ?? '',
              'name': p['name'] ?? '',
              'logo': _getLogoForCategory(p['category']),
              'category': p['category'] ?? '',
            }).toList().cast<Map<String, dynamic>>();
          }
        } else {
          _error = result['error'] ?? 'Failed to load providers';
        }
      });
    }
  }

  List<Map<String, dynamic>> get filteredProviders {
    if (searchQuery.isEmpty) return _providers;
    return _providers.where((provider) {
      return provider['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.billType} Providers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.billType} provider',
                    hintStyle: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Providers List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red),
                              SizedBox(height: 16),
                              Text(_error!, textAlign: TextAlign.center),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchProviders,
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filteredProviders.isEmpty
                          ? Center(
                              child: Text(
                                'No providers found',
                                style: TextStyle(color: Theme.of(context).hintColor),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredProviders.length,
                              itemBuilder: (context, index) {
                                final provider = filteredProviders[index];
                                return _buildProviderCard(provider);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BillDetailsScreen(
              billType: widget.billType,
              provider: provider['name'],
              providerId: provider['id'],
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  provider['logo'],
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                provider['name'],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}