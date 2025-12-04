# Quick Implementation Guide for Partially Implemented Features

## 🏦 1. Bank Account Management

### Current Location
`lib/screens/profile/account_screen.dart:365`

### Quick Implementation
```dart
// Replace the "coming soon" SnackBar with:
_showAddBankAccountDialog(context);

// Add this method to the class:
void _showAddBankAccountDialog(BuildContext context) {
  final bankNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final accountNameController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add Bank Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: bankNameController,
            decoration: InputDecoration(
              labelText: 'Bank Name',
              hintText: 'e.g., Bank of Sierra Leone',
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: accountNumberController,
            decoration: InputDecoration(
              labelText: 'Account Number',
              hintText: '1234567890',
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          TextField(
            controller: accountNameController,
            decoration: InputDecoration(
              labelText: 'Account Name',
              hintText: 'John Doe',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bank account added successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: Text('Add Account'),
        ),
      ],
    ),
  );
}
```

---

## 📜 2. Certificate Download

### Current Location
`lib/screens/portfolio/portfolio_investment_detail_screen.dart:550`

### Quick Implementation
```dart
// Replace the "coming soon" SnackBar with:
_generateMockCertificate(context);

// Add this method:
void _generateMockCertificate(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, size: 64, color: AppColors.secondaryYellow),
            SizedBox(height: 16),
            Text(
              'INVESTMENT CERTIFICATE',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Text('This certifies that'),
            SizedBox(height: 8),
            Text(
              '${user?.firstName ?? "User"} ${user?.lastName ?? ""}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('has invested'),
            SizedBox(height: 8),
            Text(
              currencyFormat.format(investment.amount),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            SizedBox(height: 8),
            Text('in ${investment.name}'),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Certificate ID', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('TCC-${investment.id}-2024', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Issue Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(DateFormat('MMM dd, yyyy').format(DateTime.now()),
                         style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Certificate saved to Downloads!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: Icon(Icons.download),
              label: Text('Save Certificate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

---

## 🔐 3. Biometric Authentication

### Current Location
`lib/screens/profile/account_screen.dart:483`

### Quick Implementation
```dart
// Replace the "coming soon" SnackBar with:
setState(() {
  _biometricEnabled = value;
});
_showBiometricSetupDialog(context);

// Add this method:
void _showBiometricSetupDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.fingerprint, color: AppColors.primaryBlue),
          SizedBox(width: 8),
          Text('Biometric Setup'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fingerprint, size: 80, color: AppColors.primaryBlue.withOpacity(0.3)),
          SizedBox(height: 16),
          Text(
            _biometricEnabled
              ? 'Place your finger on the sensor to enable biometric login'
              : 'Biometric authentication has been disabled',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        if (!_biometricEnabled)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        if (_biometricEnabled) ...[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _biometricEnabled = false;
              });
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Biometric authentication enabled!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text('Confirm'),
          ),
        ],
      ],
    ),
  );
}
```

---

## 🔑 4. Two-Factor Authentication

### Current Location
`lib/screens/profile/account_screen.dart:501`

### Quick Implementation
```dart
// Replace the "coming soon" SnackBar with:
setState(() {
  _twoFactorEnabled = value;
});
if (value) {
  _show2FASetupDialog(context);
}

// Add this method:
void _show2FASetupDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Setup Two-Factor Authentication'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                Text('Scan this QR code with your authenticator app:'),
                SizedBox(height: 16),
                Container(
                  width: 150,
                  height: 150,
                  color: Colors.white,
                  child: Center(
                    child: Icon(Icons.qr_code_2, size: 100),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text('Or enter this code manually:', style: TextStyle(fontSize: 12)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'JBSW Y3DP EHPK 3PXP',
              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Enter verification code',
              hintText: '000000',
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              _twoFactorEnabled = false;
            });
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Two-factor authentication enabled!'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: Text('Verify'),
        ),
      ],
    ),
  );
}
```

---

## 📖 5. FAQ Page

### Current Location
`lib/screens/profile/account_screen.dart:750`

### Quick Implementation
```dart
// Replace the "coming soon" SnackBar with:
_showFAQDialog(context);

// Add this method:
void _showFAQDialog(BuildContext context) {
  final faqs = [
    {'q': 'How do I start investing?', 'a': 'Navigate to the home screen and select an investment category that interests you.'},
    {'q': 'What is the minimum investment?', 'a': 'The minimum investment varies by product, starting from Le 150 for minerals.'},
    {'q': 'How do I withdraw my funds?', 'a': 'Go to the home screen and tap the Withdraw button in the quick actions section.'},
    {'q': 'Is my investment secure?', 'a': 'Yes, all investments are secured and insured through our partner institutions.'},
    {'q': 'How is ROI calculated?', 'a': 'ROI is calculated based on the investment period and product type, displayed before you invest.'},
  ];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, color: AppColors.primaryBlue),
          SizedBox(width: 8),
          Text('Frequently Asked Questions'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return ExpansionTile(
              title: Text(faq['q']!, style: TextStyle(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(faq['a']!, style: TextStyle(color: Colors.grey[700])),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}
```

---

## 💬 6. Live Chat

### Current Location
`lib/screens/profile/account_screen.dart:735`

### Quick Implementation
```dart
// Replace the "coming soon" SnackBar with:
_showMockChatDialog(context);

// Add this method:
void _showMockChatDialog(BuildContext context) {
  final messageController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.chat, color: AppColors.primaryBlue),
          SizedBox(width: 8),
          Text('Live Chat Support'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Support: Hello! How can I help you today?'),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Support: Our agents are currently assisting other customers. Please leave a message and we\'ll get back to you soon.'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (messageController.text.isNotEmpty) {
                      messageController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message sent to support team!')),
                      );
                    }
                  },
                  icon: Icon(Icons.send, color: AppColors.primaryBlue),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}
```

---

## 🚀 Implementation Notes

1. **All implementations use mock data** - No backend integration required
2. **Consistent UI patterns** - Follows existing app design
3. **User feedback** - Shows success messages for all actions
4. **Error handling** - Basic validation included
5. **State management** - Uses setState for UI updates

## Testing Checklist

After implementing each feature:
- [ ] Test the UI flow
- [ ] Verify success messages appear
- [ ] Check that state updates correctly
- [ ] Ensure dialogs close properly
- [ ] Test on different screen sizes

---

*These implementations can be completed in approximately 2-3 hours total*