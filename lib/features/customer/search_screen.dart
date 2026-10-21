import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

enum SortBy { nearest, freshest, priceLow, topRated }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialCategory, this.uglyOnly = false});
  final String? initialCategory;
  final bool uglyOnly;
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();
  String? _category;
  bool _organic = false, _ugly = false;
  double? _maxDist;
  int _minFresh = 0;
  SortBy _sort = SortBy.nearest;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _ugly = widget.uglyOnly;
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        void upd(VoidCallback f) {
          setState(f);
          setSheet(() {});
        }

        Widget chips<T>(List<T> values, T current, String Function(T) label, void Function(T) onPick) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values
                  .map((v) => ChoiceChip(
                        label: Text(label(v)),
                        selected: v == current,
                        showCheckmark: false,
                        selectedColor: AppColors.primarySoft,
                        side: BorderSide(color: v == current ? AppColors.primary : AppColors.border),
                        onSelected: (_) => upd(() => onPick(v)),
                      ))
                  .toList(),
            );

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Filters & sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              chips<SortBy>(SortBy.values, _sort, (s) => {SortBy.nearest: 'Nearest', SortBy.freshest: 'Freshest', SortBy.priceLow: 'Price: low to high', SortBy.topRated: 'Top rated'}[s]!, (v) => _sort = v),
              const SizedBox(height: 16),
              const Text('Max distance', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              chips<double?>([null, 5, 10, 25, 50], _maxDist, (v) => v == null ? 'Any' : '${v.toInt()} km', (v) => _maxDist = v),
              const SizedBox(height: 16),
              const Text('Minimum freshness', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              chips<int>([0, 50, 70, 90], _minFresh, (v) => v == 0 ? 'Any' : '$v%+', (v) => _minFresh = v),
              const SizedBox(height: 8),
              SwitchListTile(contentPadding: EdgeInsets.zero, activeColor: AppColors.primary, title: const Text('Organic only'), value: _organic, onChanged: (v) => upd(() => _organic = v)),
              SwitchListTile(contentPadding: EdgeInsets.zero, activeColor: AppColors.primary, title: const Text('Ugly but Fresh only'), value: _ugly, onChanged: (v) => upd(() => _ugly = v)),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Show results', onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(userLocationProvider).valueOrNull;
    final products = ref.watch(visibleProductsProvider);
    final q = _q.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _q,
          autofocus: widget.initialCategory == null && !widget.uglyOnly,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) {
            final u = ref.read(currentUserProvider).valueOrNull;
            if (u != null) ref.read(productRepoProvider).logSearch(u.uid, v, _category ?? '');
          },
          decoration: const InputDecoration(hintText: 'Search produce or farms', prefixIcon: Icon(Icons.search_rounded), contentPadding: EdgeInsets.symmetric(vertical: 10)),
        ),
        actions: [
          IconButton(onPressed: _openFilters, icon: const Icon(Icons.tune_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final c in [null, ...AppConstants.categories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: c == null ? const Text('All') : Row(mainAxisSize: MainAxisSize.min, children: [Icon(AppConstants.categoryIcons[c], size: 16), const SizedBox(width: 5), Text(c)]),
                    selected: _category == c,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: TextStyle(color: _category == c ? Colors.white : AppColors.text, fontWeight: FontWeight.w600),
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: products.whenUi((all) {
            var list = all.where((p) {
              if (_category != null && p.category != _category) return false;
              if (_organic && !p.isOrganic) return false;
              if (_ugly && !p.isUgly) return false;
              if (p.freshness < _minFresh) return false;
              if (q.isNotEmpty && !('${p.name} ${p.farmName} ${p.category}'.toLowerCase().contains(q))) return false;
              if (_maxDist != null && pos != null && distanceKm(pos, p.lat, p.lng)! > _maxDist!) return false;
              return true;
            }).toList();

            int byDist(Product a, Product b) =>
                pos == null ? 0 : distanceKm(pos, a.lat, a.lng)!.compareTo(distanceKm(pos, b.lat, b.lng)!);
            list.sort((a, b) {
              switch (_sort) {
                case SortBy.freshest:
                  return b.freshness.compareTo(a.freshness);
                case SortBy.priceLow:
                  return a.effectivePrice.compareTo(b.effectivePrice);
                case SortBy.topRated:
                  return b.ratingAvg.compareTo(a.ratingAvg);
                case SortBy.nearest:
                  return byDist(a, b);
              }
            });

            if (list.isEmpty) {
              return const EmptyState(icon: Icons.search_off_rounded, title: 'No matches', subtitle: 'Try a different search or relax your filters.');
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 246),
              itemCount: list.length,
              itemBuilder: (_, i) => ProductCard(product: list[i], distanceKm: distanceKm(pos, list[i].lat, list[i].lng)),
            );
          }),
        ),
      ]),
    );
  }
}
