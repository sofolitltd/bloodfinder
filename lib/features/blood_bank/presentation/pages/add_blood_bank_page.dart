import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/blood_bank_form.dart';

class AddBloodBank extends StatefulWidget {
  const AddBloodBank({super.key});

  @override
  State<AddBloodBank> createState() => _AddBloodBankState();
}

class _AddBloodBankState extends State<AddBloodBank> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Blood Bank'), centerTitle: true),
      body: SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: const BloodBankForm(),
          ),
        ),
      ),
    );
  }
}
