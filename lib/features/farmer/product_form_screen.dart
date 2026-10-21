import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmconnect/all.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;
  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();
  final _shelf = TextEditingController();
  final _uglyPct = TextEditingController(text: '20');
  final _uglyReason = TextEditingController();

  String _category = 'Vegetables';
  String _unit = 'kg';
  DateTime _harvest = DateTime.now();
  bool _organic = false, _ugly = false, _pre = false, _available = true, _busy = false;
  List<String> _urls = [];
  List<XFile> _newFiles = [];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _desc.text = p.description;
      _price.text = p.price.toString();
      _qty.text = p.quantityAvailable.toString();
      _shelf.text = p.shelfLifeDays.toString();
      _uglyPct.text = (p.uglyDiscountPercent == 0 ? 20 : p.uglyDiscountPercent).toString();
      _uglyReason.text = p.uglyReason;
      _category = AppConstants.categories.contains(p.category) ? p.category : 'Other';
      _unit = AppConstants.units.contains(p.unit) ? p.unit : 'kg';
      _harvest = p.harvestDate;
      _organic = p.isOrganic;
      _ugly = p.isUgly;
      _pre = p.isPreOrder;
      _available = p.isAvailable;
      _urls = [...p.imageUrls];
    } else {
      _shelf.text = '${AppConstants.categoryShelfLife[_category]}';
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _qty, _shelf, _uglyPct, _uglyReason]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _shelfDays => int.tryParse(_shelf.text) ?? 7;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _harvest,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (d != null) setState(() => _harvest = d);
  }

  Future<void> _pickImages() async {
    final room = 4 - _urls.length - _newFiles.length;
    if (room <= 0) return showMsg(context, 'Maximum 4 photos.');
    final files = await StorageService.pick(max: room);
    if (files.isNotEmpty) setState(() => _newFiles = [..._newFiles, ...files]);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final farm = ref.read(myFarmProvider).valueOrNull;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (farm == null || user == null) return showMsg(context, 'Create your farm profile first.');
    if (_urls.isEmpty && _newFiles.isEmpty) return showMsg(context, 'Add at least one real photo.');

    final freshness = freshnessScore(_harvest, _shelfDays);
    if (_ugly && !_pre && freshness < AppConstants.uglyMinFreshness) {
      return showMsg(context, '"Ugly but Fresh" items must be at least ${AppConstants.uglyMinFreshness}% fresh. Yours is $freshness%.');
    }

    setState(() => _busy = true);
    try {
      final uploaded = await StorageService.upload(_newFiles, 'products/${user.uid}');
      final old = widget.product;
      final p = Product(
        id: old?.id ?? '',
        farmerUid: user.uid,
        farmName: farm.farmName,
        name: _name.text.trim(),
        category: _category,
        description: _desc.text.trim(),
        unit: _unit,
        price: double.parse(_price.text),
        lat: farm.lat,
        lng: farm.lng,
        ratingAvg: old?.ratingAvg ?? 0,
        ratingCount: old?.ratingCount ?? 0,
        totalSold: old?.totalSold ?? 0,
        quantityAvailable: int.parse(_qty.text),
        shelfLifeDays: _shelfDays,
        uglyDiscountPercent: _ugly ? (int.tryParse(_uglyPct.text) ?? 20).clamp(5, 70).toInt() : 0,
        uglyReason: _ugly ? _uglyReason.text.trim() : '',
        imageUrls: [..._urls, ...uploaded],
        harvestDate: _harvest,
        createdAt: old?.createdAt ?? DateTime.now(),
        isUgly: _ugly,
        isOrganic: _organic,
        isAvailable: _available,
        isPreOrder: _pre,
      );
      await ref.read(productRepoProvider).save(p, isNew: !_isEdit);
      if (mounted) {
        showMsg(context, _isEdit ? 'Product updated' : 'Product added');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showMsg(context, 'Could not save: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final freshness = freshnessScore(_harvest, _shelfDays);
    final hint = suggestedDiscount(freshness);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'Add product')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
          const Text('Photos', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Use real photos - customers trust honest pictures.', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 84,
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))),
                  child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                ),
              ),
              for (var i = 0; i < _urls.length; i++) _thumb(NetImage(_urls[i], width: 84, height: 84, radius: 14), () => setState(() => _urls.removeAt(i))),
              for (var i = 0; i < _newFiles.length; i++)
                _thumb(
                  FutureBuilder<List<int>>(future: _newFiles[i].readAsBytes(), builder: (context, snapshot) => ClipRRect(borderRadius: BorderRadius.circular(14), child: snapshot.hasData ? Image.memory(Uint8List.fromList(snapshot.data!), width: 84, height: 84, fit: BoxFit.cover) : const SizedBox(width: 84, height: 84, child: Center(child: CircularProgressIndicator(strokeWidth: 2))))),
                  () => setState(() => _newFiles.removeAt(i)),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          AppField(controller: _name, label: 'Product name', validator: requiredValidator),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: AppConstants.categories.map((c) => DropdownMenuItem(value: c, child: Row(children: [Icon(AppConstants.categoryIcons[c], size: 18), const SizedBox(width: 8), Text(c)]))).toList(),
            onChanged: (v) => setState(() {
              _category = v!;
              if (!_isEdit) _shelf.text = '${AppConstants.categoryShelfLife[v]}';
            }),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              flex: 3,
              child: AppField(
                controller: _price,
                label: 'Price (₹)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter a price' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: _unit,
                decoration: const InputDecoration(labelText: 'Per'),
                items: AppConstants.units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _unit = v!),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          AppField(
            controller: _qty,
            label: 'Quantity available',
            keyboardType: TextInputType.number,
            validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0 ? 'Enter a whole number' : null,
          ),
          const SizedBox(height: 14),
          AppField(controller: _desc, label: 'Description (optional)', maxLines: 3),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: const Text('Pre-order (not harvested yet)', style: TextStyle(fontWeight: FontWeight.w600)),
            value: _pre,
            onChanged: (v) => setState(() => _pre = v),
          ),
          AppField(
            controller: TextEditingController(text: fmtDate(_harvest)),
            label: _pre ? 'Expected harvest date' : 'Harvest date',
            readOnly: true,
            onTap: _pickDate,
            prefixIcon: Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 14),
          AppField(
            controller: _shelf,
            label: 'Shelf life (days)',
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter days' : null,
          ),
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.primarySoft,
            child: Row(children: [
              Icon(Icons.eco_rounded, color: freshnessColor(freshness)),
              const SizedBox(width: 10),
              Expanded(child: Text('Freshness score customers will see: $freshness% (${freshnessLabel(freshness)})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            ]),
          ),
          if (hint > 0 && !_ugly)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Tip: freshness is dropping - a $hint% discount via "Ugly but Fresh" can help sell it.', style: const TextStyle(color: AppColors.accent, fontSize: 12.5)),
            ),
          const SizedBox(height: 8),
          SwitchListTile(contentPadding: EdgeInsets.zero, activeThumbColor: AppColors.primary, title: const Text('Organic', style: TextStyle(fontWeight: FontWeight.w600)), value: _organic, onChanged: (v) => setState(() => _organic = v)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: const Text('Ugly but Fresh', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Imperfect shape or size, sold at a discount'),
            value: _ugly,
            onChanged: (v) => setState(() => _ugly = v),
          ),
          if (_ugly) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: AppField(controller: _uglyPct, label: 'Discount %', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: AppField(controller: _uglyReason, label: 'Why? (e.g. odd shape)')),
            ]),
          ],
          SwitchListTile(contentPadding: EdgeInsets.zero, activeThumbColor: AppColors.primary, title: const Text('Visible to customers', style: TextStyle(fontWeight: FontWeight.w600)), value: _available, onChanged: (v) => setState(() => _available = v)),
          const SizedBox(height: 16),
          PrimaryButton(label: _isEdit ? 'Save changes' : 'Publish product', loading: _busy, onPressed: _save),
        ]),
      ),
    );
  }

  Widget _thumb(Widget child, VoidCallback onRemove) => Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Stack(children: [
          child,
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close_rounded, size: 13, color: Colors.white)),
            ),
          ),
        ]),
      );
}
