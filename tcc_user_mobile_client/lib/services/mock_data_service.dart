import '../models/user_model.dart';
import '../models/investment_model.dart';
import '../models/transaction_model.dart';
import '../models/agent_model.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Mock user data
  UserModel get currentUser => UserModel.mock();

  // Mock investment products
  List<InvestmentProduct> get fixedReturnProducts => [
    InvestmentProduct(
      id: '1',
      name: '1 Lot',
      unit: 'Lot',
      price: 234.00,
      roi: 12.0,
      minPeriod: 6,
      description: 'Small agricultural investment unit',
      category: 'AGRICULTURE',
    ),
    InvestmentProduct(
      id: '2',
      name: '1 Plot',
      unit: 'Plot',
      price: 1000.00,
      roi: 12.0,
      minPeriod: 12,
      description: 'Medium agricultural investment unit',
      category: 'AGRICULTURE',
    ),
    InvestmentProduct(
      id: '3',
      name: '1 Farm',
      unit: 'Farm',
      price: 2340.00,
      roi: 12.0,
      minPeriod: 24,
      description: 'Large agricultural investment unit',
      category: 'AGRICULTURE',
    ),
  ];

  // Get products by category
  List<InvestmentProduct> getProductsByCategory(String category) {
    switch (category.toUpperCase()) {
      case 'AGRICULTURE':
        return [
          InvestmentProduct(
            id: 'agri_1',
            name: 'Land Lease',
            unit: 'Hectare',
            price: 2837.00,
            roi: 50.6,
            minPeriod: 12,
            description: 'Invest in agricultural land leasing. Fixed returns guaranteed after harvest season.',
            category: 'AGRICULTURE',
          ),
          InvestmentProduct(
            id: 'agri_2',
            name: 'Processing',
            unit: 'Unit',
            price: 2837.00,
            roi: 50.6,
            minPeriod: 6,
            description: 'Invest in agricultural processing facilities. Earn from processing cocoa, coffee, and other crops.',
            category: 'AGRICULTURE',
          ),
          InvestmentProduct(
            id: 'agri_3',
            name: '1 Lot',
            unit: 'Lot',
            price: 234.00,
            roi: 12.0,
            minPeriod: 6,
            description: 'Small agricultural investment unit. Perfect for beginners looking to invest in agriculture.',
            category: 'AGRICULTURE',
          ),
          InvestmentProduct(
            id: 'agri_4',
            name: '1 Plot',
            unit: 'Plot',
            price: 1000.00,
            roi: 12.0,
            minPeriod: 12,
            description: 'Medium agricultural investment unit. Diversify your portfolio with farm plots.',
            category: 'AGRICULTURE',
          ),
          InvestmentProduct(
            id: 'agri_5',
            name: '1 Farm',
            unit: 'Farm',
            price: 2340.00,
            roi: 12.0,
            minPeriod: 24,
            description: 'Large agricultural investment unit. Maximize returns with full farm ownership.',
            category: 'AGRICULTURE',
          ),
        ];
      case 'MINERALS':
        return [
          InvestmentProduct(
            id: 'mineral_1',
            name: 'Silver',
            unit: 'Gram',
            price: 150.00,
            roi: 75.0,
            minPeriod: 6,
            description: 'Invest in silver reserves. Stable precious metal with industrial demand.',
            category: 'MINERALS',
          ),
          InvestmentProduct(
            id: 'mineral_2',
            name: 'Gold',
            unit: 'Gram',
            price: 234.00,
            roi: 99.0,
            minPeriod: 12,
            description: 'Invest in gold reserves. Premium precious metal with strong returns.',
            category: 'MINERALS',
          ),
          InvestmentProduct(
            id: 'mineral_3',
            name: 'Platinum',
            unit: 'Gram',
            price: 350.00,
            roi: 85.0,
            minPeriod: 18,
            description: 'Invest in platinum. Rare precious metal with high value and industrial applications.',
            category: 'MINERALS',
          ),
        ];
      case 'EDUCATION':
        return [
          InvestmentProduct(
            id: 'edu_1',
            name: 'Student Loan Fund',
            unit: 'Share',
            price: 500.00,
            roi: 10.0,
            minPeriod: 36,
            description: 'Invest in student education loans. Support education while earning stable returns.',
            category: 'EDUCATION',
          ),
          InvestmentProduct(
            id: 'edu_2',
            name: 'School Infrastructure',
            unit: 'Unit',
            price: 2000.00,
            roi: 12.0,
            minPeriod: 48,
            description: 'Fund school building and infrastructure projects. Long-term investment in education.',
            category: 'EDUCATION',
          ),
          InvestmentProduct(
            id: 'edu_3',
            name: 'Scholarship Fund',
            unit: 'Share',
            price: 1000.00,
            roi: 8.0,
            minPeriod: 24,
            description: 'Contribute to scholarship programs. Make a difference while earning returns.',
            category: 'EDUCATION',
          ),
          InvestmentProduct(
            id: 'edu_4',
            name: 'Vocational Training',
            unit: 'Unit',
            price: 1500.00,
            roi: 15.0,
            minPeriod: 18,
            description: 'Invest in vocational training centers. Support skill development programs.',
            category: 'EDUCATION',
          ),
        ];
      case 'CURRENCY':
        return [
          InvestmentProduct(
            id: 'currency_1',
            name: 'USD/SLL',
            unit: 'Lot',
            price: 1000.00,
            roi: 45.0,
            minPeriod: 3,
            description: 'Invest in US Dollar vs Sierra Leone Leone forex pair. Short-term currency trading.',
            category: 'CURRENCY',
          ),
          InvestmentProduct(
            id: 'currency_2',
            name: 'EUR/SLL',
            unit: 'Lot',
            price: 1200.00,
            roi: 42.0,
            minPeriod: 3,
            description: 'Invest in Euro vs Sierra Leone Leone forex pair. European currency exposure.',
            category: 'CURRENCY',
          ),
          InvestmentProduct(
            id: 'currency_3',
            name: 'GBP/SLL',
            unit: 'Lot',
            price: 1100.00,
            roi: 40.0,
            minPeriod: 3,
            description: 'Invest in British Pound vs Sierra Leone Leone. Strong currency pair.',
            category: 'CURRENCY',
          ),
          InvestmentProduct(
            id: 'currency_4',
            name: 'USD/EUR',
            unit: 'Lot',
            price: 1500.00,
            roi: 38.0,
            minPeriod: 6,
            description: 'Invest in USD/EUR major forex pair. Global currency trading opportunity.',
            category: 'CURRENCY',
          ),
          InvestmentProduct(
            id: 'currency_5',
            name: 'Crypto Index',
            unit: 'Share',
            price: 2000.00,
            roi: 55.0,
            minPeriod: 12,
            description: 'Invest in diversified cryptocurrency index. Digital currency exposure.',
            category: 'CURRENCY',
          ),
        ];
      default:
        return [];
    }
  }

  // Mock user investments
  List<InvestmentModel> get userInvestments => [
    InvestmentModel(
      id: '1',
      name: 'Agriculture - 2 Plots',
      category: 'AGRICULTURE',
      amount: 2000.00,
      roi: 12.0,
      period: 12,
      expectedReturn: 2240.00,
      startDate: DateTime(2024, 10, 1),
      endDate: DateTime(2025, 10, 1),
      status: 'ACTIVE',
    ),
    InvestmentModel(
      id: '2',
      name: 'Gold Investment',
      category: 'MINERALS',
      amount: 5000.00,
      roi: 15.0,
      period: 6,
      expectedReturn: 5750.00,
      startDate: DateTime(2024, 8, 15),
      endDate: DateTime(2025, 2, 15),
      status: 'ACTIVE',
    ),
    InvestmentModel(
      id: '3',
      name: 'Education Fund',
      category: 'EDUCATION',
      amount: 3000.00,
      roi: 10.0,
      period: 18,
      expectedReturn: 3300.00,
      startDate: DateTime(2024, 6, 1),
      endDate: DateTime(2025, 12, 1),
      status: 'ACTIVE',
    ),
  ];

  // Mock transactions
  List<TransactionModel> get recentTransactions => [
    TransactionModel(
      id: '1',
      transactionId: 'TXN20241025001',
      type: 'DEPOSIT',
      amount: 10000.00,
      status: 'COMPLETED',
      date: DateTime(2024, 10, 25),
      description: 'Bank deposit',
      accountInfo: 'Bank of Sierra Leone ****4567',
    ),
    TransactionModel(
      id: '2',
      transactionId: 'TXN20241024001',
      type: 'INVESTMENT',
      amount: -2000.00,
      status: 'COMPLETED',
      date: DateTime(2024, 10, 24),
      description: 'Investment in Agriculture',
      recipient: 'TCC Agriculture Fund',
    ),
    TransactionModel(
      id: '3',
      transactionId: 'TXN20241023001',
      type: 'BILL_PAYMENT',
      amount: -150.00,
      status: 'COMPLETED',
      date: DateTime(2024, 10, 23),
      description: 'Electricity bill payment',
      recipient: 'EDSA',
    ),
    TransactionModel(
      id: '4',
      transactionId: 'TXN20241022001',
      type: 'TRANSFER',
      amount: -500.00,
      status: 'COMPLETED',
      date: DateTime(2024, 10, 22),
      description: 'Transfer to friend',
      recipient: 'John Kamara',
      accountInfo: '+232 76 456 7890',
    ),
    TransactionModel(
      id: '5',
      transactionId: 'TXN20241026001',
      type: 'DEPOSIT',
      amount: 5000.00,
      status: 'PENDING',
      date: DateTime(2024, 10, 26),
      description: 'Mobile money deposit',
      accountInfo: 'Airtel Money',
    ),
  ];

  // Mock dashboard stats
  Map<String, dynamic> get dashboardStats => {
    'totalInvested': 10000.00,
    'expectedReturns': 11290.00,
    'activeInvestments': 3,
    'totalEarnings': 1200.00,
  };

  // Mock authentication
  Future<bool> login(String email, String password) async {
    await Future.delayed(Duration(seconds: 2));
    return email.isNotEmpty && password.isNotEmpty;
  }

  Future<bool> register(Map<String, String> userData) async {
    await Future.delayed(Duration(seconds: 2));
    return true;
  }

  Future<bool> verifyOTP(String otp) async {
    await Future.delayed(Duration(seconds: 1));
    return otp.length == 6;
  }

  // Mock agent data
  List<AgentModel> get allAgents => [
    AgentModel(
      id: 'agent_1',
      firstName: 'Mohamed',
      lastName: 'Kamara',
      phoneNumber: '+232 76 123 4567',
      email: 'mohamed.kamara@tccagent.com',
      bankName: 'Bank of Sierra Leone',
      bankBranchName: 'Freetown Central Branch',
      bankBranchAddress: 'Siaka Stevens Street, Freetown',
      ifscCode: 'BOSL001',
      latitude: 8.4657,
      longitude: -13.2317,
      address: '45 Wilkinson Road, Freetown',
      isActive: true,
      rating: 4.8,
      totalTransactions: 245,
      commissionRate: 2.5,
    ),
    AgentModel(
      id: 'agent_2',
      firstName: 'Fatmata',
      lastName: 'Sesay',
      phoneNumber: '+232 77 234 5678',
      email: 'fatmata.sesay@tccagent.com',
      bankName: 'Union Trust Bank',
      bankBranchName: 'Bo Town Branch',
      bankBranchAddress: 'Coronation Field Road, Bo',
      ifscCode: 'UTB002',
      latitude: 7.9644,
      longitude: -11.7381,
      address: '23 Kanga Road, Bo',
      isActive: true,
      rating: 4.9,
      totalTransactions: 312,
      commissionRate: 2.0,
    ),
    AgentModel(
      id: 'agent_3',
      firstName: 'Ibrahim',
      lastName: 'Turay',
      phoneNumber: '+232 78 345 6789',
      email: 'ibrahim.turay@tccagent.com',
      bankName: 'Ecobank Sierra Leone',
      bankBranchName: 'Kenema Branch',
      bankBranchAddress: 'Hangha Road, Kenema',
      ifscCode: 'ECOB003',
      latitude: 7.8767,
      longitude: -11.1896,
      address: '12 Blama Road, Kenema',
      isActive: true,
      rating: 4.6,
      totalTransactions: 189,
      commissionRate: 2.5,
    ),
    AgentModel(
      id: 'agent_4',
      firstName: 'Aminata',
      lastName: 'Bangura',
      phoneNumber: '+232 79 456 7890',
      email: 'aminata.bangura@tccagent.com',
      bankName: 'First International Bank',
      bankBranchName: 'Makeni Branch',
      bankBranchAddress: 'Magburaka Highway, Makeni',
      ifscCode: 'FIB004',
      latitude: 8.8852,
      longitude: -12.0431,
      address: '67 Rogbere Road, Makeni',
      isActive: true,
      rating: 4.7,
      totalTransactions: 221,
      commissionRate: 2.0,
    ),
    AgentModel(
      id: 'agent_5',
      firstName: 'Abdul',
      lastName: 'Conteh',
      phoneNumber: '+232 76 567 8901',
      email: 'abdul.conteh@tccagent.com',
      bankName: 'Sierra Leone Commercial Bank',
      bankBranchName: 'Waterloo Branch',
      bankBranchAddress: 'Peninsular Highway, Waterloo',
      ifscCode: 'SLCB005',
      latitude: 8.3389,
      longitude: -13.0703,
      address: '89 Main Motor Road, Waterloo',
      isActive: true,
      rating: 4.5,
      totalTransactions: 167,
      commissionRate: 2.5,
    ),
    AgentModel(
      id: 'agent_6',
      firstName: 'Mariama',
      lastName: 'Jalloh',
      phoneNumber: '+232 77 678 9012',
      email: 'mariama.jalloh@tccagent.com',
      bankName: 'Guaranty Trust Bank',
      bankBranchName: 'Lumley Branch',
      bankBranchAddress: 'Lumley Beach Road, Freetown',
      ifscCode: 'GTB006',
      latitude: 8.4547,
      longitude: -13.2729,
      address: '34 Lumley Beach Road, Freetown',
      isActive: true,
      rating: 4.9,
      totalTransactions: 298,
      commissionRate: 2.0,
    ),
    AgentModel(
      id: 'agent_7',
      firstName: 'Sahr',
      lastName: 'Williams',
      phoneNumber: '+232 78 789 0123',
      email: 'sahr.williams@tccagent.com',
      bankName: 'Access Bank',
      bankBranchName: 'Kissy Branch',
      bankBranchAddress: 'Kissy Bypass, Freetown',
      ifscCode: 'ACC007',
      latitude: 8.4842,
      longitude: -13.2097,
      address: '56 Kissy Road, Freetown',
      isActive: false,
      rating: 4.3,
      totalTransactions: 134,
      commissionRate: 2.5,
    ),
    AgentModel(
      id: 'agent_8',
      firstName: 'Hawa',
      lastName: 'Koroma',
      phoneNumber: '+232 79 890 1234',
      email: 'hawa.koroma@tccagent.com',
      bankName: 'Zenith Bank',
      bankBranchName: 'Hill Station Branch',
      bankBranchAddress: 'Hill Station, Freetown',
      ifscCode: 'ZEN008',
      latitude: 8.4289,
      longitude: -13.2181,
      address: '78 Hill Station Road, Freetown',
      isActive: true,
      rating: 4.8,
      totalTransactions: 256,
      commissionRate: 2.0,
    ),
  ];

  // Search agents by location
  Future<List<AgentModel>> searchAgentsByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));

    final agents = allAgents
        .where((agent) => agent.isActive)
        .map((agent) {
          final distance = agent.distanceFrom(latitude, longitude);
          return MapEntry(agent, distance);
        })
        .where((entry) => entry.value <= radiusKm)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return agents.map((entry) => entry.key).toList();
  }

  // Search agents by phone number
  Future<List<AgentModel>> searchAgentsByPhone(String phoneNumber) async {
    await Future.delayed(Duration(milliseconds: 300));

    return allAgents
        .where((agent) =>
            agent.isActive &&
            agent.phoneNumber.toLowerCase().contains(phoneNumber.toLowerCase()))
        .toList();
  }

  // Search agents by bank branch
  Future<List<AgentModel>> searchAgentsByBankBranch(String branchName) async {
    await Future.delayed(Duration(milliseconds: 300));

    return allAgents
        .where((agent) =>
            agent.isActive &&
            (agent.bankBranchName.toLowerCase().contains(branchName.toLowerCase()) ||
             agent.bankName.toLowerCase().contains(branchName.toLowerCase())))
        .toList();
  }

  // Get agent by ID
  Future<AgentModel?> getAgentById(String agentId) async {
    await Future.delayed(Duration(milliseconds: 200));

    try {
      return allAgents.firstWhere((agent) => agent.id == agentId);
    } catch (e) {
      return null;
    }
  }
}
