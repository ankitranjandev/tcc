import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'bill_details_screen.dart';

class BillProviderScreen extends StatefulWidget {
  final String billType;

  const BillProviderScreen({super.key, required this.billType});

  @override
  State<BillProviderScreen> createState() => _BillProviderScreenState();
}

class _BillProviderScreenState extends State<BillProviderScreen> {
  String searchQuery = '';

  Map<String, List<Map<String, dynamic>>> providers = {
    'Electricity': [
      {'name': 'EDSA - Sierra Leone', 'logo': '⚡', 'customers': '1.2M'},
      {'name': 'Eskom - South Africa', 'logo': '⚡', 'customers': '5.8M'},
      {'name': 'KPLC - Kenya Power', 'logo': '⚡', 'customers': '3.2M'},
      {'name': 'ECG - Ghana', 'logo': '⚡', 'customers': '2.9M'},
      {'name': 'NEPA - Nigeria', 'logo': '⚡', 'customers': '4.5M'},
      {'name': 'ZESCO - Zambia', 'logo': '⚡', 'customers': '1.7M'},
    ],
    'Mobile': [
      {'name': 'Orange Sierra Leone', 'logo': '📱', 'customers': '3.5M'},
      {'name': 'Africell', 'logo': '📱', 'customers': '2.8M'},
      {'name': 'MTN', 'logo': '📱', 'customers': '4.3M'},
      {'name': 'Airtel Africa', 'logo': '📱', 'customers': '3.2M'},
      {'name': 'Vodacom', 'logo': '📱', 'customers': '2.1M'},
    ],
    'Water': [
      {'name': 'Guma Valley Water', 'logo': '💧', 'customers': '0.8M'},
      {'name': 'NWSC - Uganda', 'logo': '💧', 'customers': '2.1M'},
      {'name': 'Rand Water - South Africa', 'logo': '💧', 'customers': '3.8M'},
      {'name': 'GWCL - Ghana Water', 'logo': '💧', 'customers': '1.3M'},
      {'name': 'Lagos Water Corporation', 'logo': '💧', 'customers': '2.6M'},
    ],
    'DTH': [
      {'name': 'DStv', 'logo': '📡', 'customers': '8.3M'},
      {'name': 'GOtv', 'logo': '📡', 'customers': '5.9M'},
      {'name': 'StarTimes', 'logo': '📡', 'customers': '4.5M'},
      {'name': 'Canal+', 'logo': '📡', 'customers': '3.1M'},
      {'name': 'Zuku', 'logo': '📡', 'customers': '1.9M'},
    ],
  };

  List<Map<String, dynamic>> get filteredProviders {
    final list = providers[widget.billType] ?? [];
    if (searchQuery.isEmpty) return list;
    return list.where((provider) {
      return provider['name'].toLowerCase().contains(searchQuery.toLowerCase());
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
              child: ListView.builder(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider['name'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${provider['customers']} customers',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
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