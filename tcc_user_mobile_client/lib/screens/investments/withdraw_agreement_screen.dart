import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

class WithdrawAgreementScreen extends StatefulWidget {
  const WithdrawAgreementScreen({super.key});

  @override
  State<WithdrawAgreementScreen> createState() => _WithdrawAgreementScreenState();
}

class _WithdrawAgreementScreenState extends State<WithdrawAgreementScreen> {
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Withdraw'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Investment Header (faded)
              Opacity(
                opacity: 0.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wallet, size: 48, color: Colors.yellow.shade700),
                        SizedBox(width: 16),
                        Text(
                          'Gold',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Chip(
                          label: Text('Minerals'),
                          backgroundColor: Colors.yellow.shade100,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text('Qty', style: TextStyle(fontSize: 14)),
                    Text('100 gms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 16),
                    Text('Total Amount to be withdrawn', style: TextStyle(fontSize: 16)),
                    Text('\$ 45,688', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Agreement Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined, color: AppColors.primaryBlue),
                        SizedBox(width: 12),
                        Text(
                          'Agreement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Lorem Ipsum is simply dummy text of the printing. Lorem Ipsum is simply dummy text of the printing. Lorem Ipsum is simply dummy text of the printing Lorem Ipsum is simply dummy text of the printing. Lorem Ipsum is simply dummy text of the printing. Lorem Ipsum is simply dummy text of the printing. Lorem Ipsum is simply dummy text of the printing. Lorem Ipsum is simply dummy text of the printing Lorem Ipsum is simply dummy text of the printing. Lorem Ipsum is simply dummy text of the printing. Lorem Ipsum is simply dummy text of the printing. Lorem Ipsum is simply dummy text of the printing. ',
                      style: TextStyle(fontSize: 12, height: 1.5),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('Read more', style: TextStyle(color: AppColors.primaryBlue)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (value) => setState(() => _acceptedTerms = value!),
                    activeColor: AppColors.primaryBlue,
                  ),
                  Expanded(
                    child: Text(
                      'I accept all the terms and conditions',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              Spacer(),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _acceptedTerms
                      ? () => context.push('/withdraw-success')
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
