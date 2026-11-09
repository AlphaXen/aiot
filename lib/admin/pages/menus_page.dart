import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/restaurant.dart';
import '../admin_store.dart';
import '../admin_theme.dart';
import '../widgets/common.dart';

class MenusPage extends StatefulWidget {
  const MenusPage({super.key});

  @override
  State<MenusPage> createState() => _MenusPageState();
}

class _MenusPageState extends State<MenusPage> {
  String _id = RestaurantStore.instance.restaurants.first.id;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final st = RestaurantStore.instance;
    final r = st.byId(_id);
    final soldOut = r.menus.where((m) => m.soldOut).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: '메뉴 관리',
          description: '사용자 앱 식당 상세의 "오늘의 메뉴"에 표시됩니다',
          actions: [
            FilledButton.icon(
              onPressed: () => _menuDialog(context, r),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('메뉴 추가'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final x in st.restaurants)
              ChoiceChip(
                avatar: Icon(x.icon, size: 18, color: x.id == _id ? Colors.white : AdminTokens.accent),
                label: Text('${x.name} ${x.menus.length}'),
                selected: x.id == _id,
                showCheckmark: false,
                selectedColor: AdminTokens.accent,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, color: x.id == _id ? Colors.white : t.textSub),
                side: BorderSide(color: x.id == _id ? AdminTokens.accent : t.border),
                backgroundColor: t.panel,
                onSelected: (_) => setState(() => _id = x.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Panel(
          title: '${r.name} 오늘의 메뉴',
          subtitle: '${r.menus.length}개 · 품절 $soldOut개 · ${r.openHours}',
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: HScroll(
            minWidth: 780,
            child: AdminTable(
              columns: const ['메뉴', '가격', '태그', '판매 상태', ''],
              flex: const [28, 12, 12, 16, 12],
              emptyText: '등록된 메뉴가 없습니다. "메뉴 추가"를 눌러 등록하세요',
              onRowTap: (i) => _menuDialog(context, r, edit: r.menus[i]),
              rows: [
                for (final m in r.menus)
                  [
                    Text(
                      m.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: m.soldOut ? t.textMuted : t.text,
                        decoration: m.soldOut ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(won(m.price), style: TextStyle(color: t.text)),
                    m.tag == null
                        ? Text('-', style: TextStyle(color: t.textMuted))
                        : StatusBadge(label: m.tag!, color: AdminTokens.accent, icon: Icons.local_offer_rounded),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(value: !m.soldOut, onChanged: (v) => _setSoldOut(r, m, !v)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            m.soldOut ? '품절' : '판매 중',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: m.soldOut ? AdminTokens.critical : AdminTokens.good,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: '수정',
                          icon: Icon(Icons.edit_outlined, size: 19, color: t.textSub),
                          onPressed: () => _menuDialog(context, r, edit: m),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: '삭제',
                          icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AdminTokens.critical),
                          onPressed: () => _delete(context, r, m),
                        ),
                      ],
                    ),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _setSoldOut(Restaurant r, MenuItem m, bool soldOut) {
    RestaurantStore.instance.updateMenu(m, soldOut: soldOut);
    AdminStore.instance.log(AdminLog(LogLevel.info, r.name, '"${m.name}" ${soldOut ? '품절 처리' : '판매 재개'}', actor: AdminStore.adminName));
  }

  Future<void> _delete(BuildContext context, Restaurant r, MenuItem m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메뉴 삭제'),
        content: Text('${r.name}의 "${m.name}"을(를) 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminTokens.critical),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    RestaurantStore.instance.removeMenu(r, m);
    AdminStore.instance.log(AdminLog(LogLevel.info, r.name, '메뉴 "${m.name}" 삭제', actor: AdminStore.adminName));
  }

  void _menuDialog(BuildContext context, Restaurant r, {MenuItem? edit}) {
    final name = TextEditingController(text: edit?.name);
    final price = TextEditingController(text: edit?.price.toString());
    final tag = TextEditingController(text: edit?.tag);
    String? error;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(edit == null ? '${r.name} 메뉴 추가' : '메뉴 수정'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '메뉴 이름'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: '가격', suffixText: '원'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tag,
                  decoration: const InputDecoration(labelText: '태그 (선택)', hintText: '예: 인기, 신메뉴'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AdminTokens.critical, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            FilledButton(
              onPressed: () {
                final n = name.text.trim();
                final p = int.tryParse(price.text);
                if (n.isEmpty || p == null) {
                  setState(() => error = '메뉴 이름과 가격을 입력하세요');
                  return;
                }
                final tg = tag.text.trim().isEmpty ? null : tag.text.trim();
                final st = RestaurantStore.instance;
                if (edit == null) {
                  st.addMenu(r, MenuItem(n, p, tag: tg));
                  AdminStore.instance.log(AdminLog(LogLevel.info, r.name, '메뉴 "$n" 추가 (${won(p)})', actor: AdminStore.adminName));
                } else {
                  edit.tag = tg;
                  st.updateMenu(edit, name: n, price: p);
                  AdminStore.instance.log(AdminLog(LogLevel.info, r.name, '메뉴 "$n" 수정', actor: AdminStore.adminName));
                }
                Navigator.pop(context);
              },
              child: Text(edit == null ? '추가' : '저장'),
            ),
          ],
        ),
      ),
    );
  }
}
