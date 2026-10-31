import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';

class ShopProfileData {
  final String shopName;
  final String address;
  final String phone;
  final String panNumber;

  const ShopProfileData({
    required this.shopName,
    required this.address,
    required this.phone,
    required this.panNumber,
  });
}

/// Modal bottom sheet to edit shop name, address, phone, and receipt PAN/VAT details.
class ShopProfileSheet extends StatefulWidget {
  const ShopProfileSheet({
    super.key,
    this.initialData = const ShopProfileData(
      shopName: 'My Kirana Store',
      address: '',
      phone: '',
      panNumber: '',
    ),
  });

  final ShopProfileData initialData;

  static Future<ShopProfileData?> show(
    BuildContext context, {
    ShopProfileData initialData = const ShopProfileData(
      shopName: 'My Kirana Store',
      address: '',
      phone: '',
      panNumber: '',
    ),
  }) {
    return showModalBottomSheet<ShopProfileData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ShopProfileSheet(initialData: initialData),
    );
  }

  @override
  State<ShopProfileSheet> createState() => _ShopProfileSheetState();
}

class _ShopProfileSheetState extends State<ShopProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _panController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData.shopName);
    _addressController = TextEditingController(text: widget.initialData.address);
    _phoneController = TextEditingController(text: widget.initialData.phone);
    _panController = TextEditingController(text: widget.initialData.panNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.inputBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),
              Text(
                'Shop Profile & Receipt',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
              ),
              const Gap(16),

              AuthTextField(
                controller: _nameController,
                label: 'Store / Business Name',
                hintText: 'e.g. Ganesh Kirana Pasal',
              ),
              const Gap(12),
              AuthTextField(
                controller: _addressController,
                label: 'Store Address',
                hintText: 'Location in Nepal',
              ),
              const Gap(12),
              AuthTextField(
                controller: _phoneController,
                label: 'Contact Phone',
                hintText: '98XXXXXXXX',
                keyboardType: TextInputType.phone,
              ),
              const Gap(12),
              AuthTextField(
                controller: _panController,
                label: 'PAN / VAT Number',
                hintText: '9-digit PAN',
              ),
              const Gap(16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ShopProfileData(
                        shopName: _nameController.text.trim(),
                        address: _addressController.text.trim(),
                        phone: _phoneController.text.trim(),
                        panNumber: _panController.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Shop Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

