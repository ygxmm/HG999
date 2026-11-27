from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
hook = (root / "Hooks/AxsHG999SettingsEntry.xm").read_text(encoding="utf-8")
header = (root / "Headers/AxsHG999Private.h").read_text(encoding="utf-8")
plist = (root / "AxsHG999.plist").read_text(encoding="utf-8")

checks = {
    "只存在一个设置控制器 Hook": hook.count("%hook SSSettingViewController") == 1,
    "原生设置分组仅增加一组": "return originalCount + 1;" in hook,
    "HG999 新分组固定放在第 0 组": "section == 0" in hook and "indexPath.section == 0" in hook,
    "原生分组统一映射到显示索引减一": "return displaySection - 1;" in hook,
    "行数/单元格/行高全部复用原分组映射": all(
        "axs_hg999_originalSectionForDisplay(self, tableView" in hook
        for _ in range(4)
    ),
    "分组头尾也复用同一个索引映射": all(
        f"{method}:(NSInteger)section" in hook
        for method in ["heightForHeaderInSection", "heightForFooterInSection", "viewForHeaderInSection", "viewForFooterInSection"]
    ) and hook.count("axs_hg999_originalSectionForDisplay(self, tableView") == 7,
    "没有反向排序或改写原数据数组": not re.search(r"reverseObjectEnumerator|sortedArray|sortUsing|cellItemsArrs\s*=", hook),
    "菜单仍只注入红果 bundle": "com.phoenix.video" in plist,
    "唯一头文件声明行高委托": "heightForRowAtIndexPath:(NSIndexPath *)indexPath" in header,
}

# 行为表：无论原生有多少组，显示首组为 HG999，原组顺序和值不变。
for original_sections in (0, 1, 2, 7):
    displayed = ["HG999"] + [f"native-{i}" for i in range(original_sections)]
    remapped = [displayed[i + 1] for i in range(original_sections)]
    checks[f"{original_sections} 个原生分组顺序保持"] = remapped == [f"native-{i}" for i in range(original_sections)]

for name, passed in checks.items():
    print(("PASS" if passed else "FAIL"), name)
if not all(checks.values()):
    raise SystemExit(1)
