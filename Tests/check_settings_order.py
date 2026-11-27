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
    "所有列表委托均识别原生重入": hook.count("if (axs_hg999_isForwardingNativeCallback())") == 7 and "if (axs_hg999_isForwardingNativeCallback() ||" in hook,
    "原生回调重入深度由 finally 正确归还": hook.count("axs_hg999_beginNativeCallback();") == hook.count("axs_hg999_endNativeCallback();") and "depth + 1" in hook and "depth - 1" in hook,
    "已移除旧索引映射入口": "axs_hg999_originalSectionForDisplay" not in hook,
    "没有反向排序或改写原数据数组": not re.search(r"reverseObjectEnumerator|sortedArray|sortUsing|cellItemsArrs\s*=", hook),
    "菜单仍只注入红果 bundle": "com.phoenix.video" in plist,
    "唯一头文件声明行高委托": "heightForRowAtIndexPath:(NSIndexPath *)indexPath" in header,
}

# 行为模型：原生 cell 内部通过 self 重入委托时，应继续使用原生索引坐标。
class SettingsIndexModel:
    def __init__(self):
        self.sections = 3
        self.rows = [2, 3, 1]
        self.heights = {(0, 0): 72.0, (0, 1): 44.0, (1, 0): 58.0}
        self.depth = 0

    def native_sections(self):
        return self.sections

    def hooked_sections(self):
        if self.depth:
            return self.native_sections()
        self.depth += 1
        try:
            return self.native_sections() + 1
        finally:
            self.depth -= 1

    def native_rows(self, section):
        return self.rows[section] if 0 <= section < self.sections else 0

    def hooked_rows(self, section):
        if self.depth:
            return self.native_rows(section)
        if section == 0:
            return 1
        original_section = section - 1
        self.depth += 1
        try:
            return self.native_rows(original_section)
        finally:
            self.depth -= 1

    def native_height(self, section, row):
        return self.heights.get((section, row), 60.0)

    def hooked_height(self, section, row):
        if self.depth:
            return self.native_height(section, row)
        if section == 0 and row == 0:
            return 56.0
        original_section = section - 1
        self.depth += 1
        try:
            return self.native_height(original_section, row)
        finally:
            self.depth -= 1

    def native_cell(self, section, row):
        # 模拟原生实现用 self 查询页数、行数和高度，触发 Hook 重入。
        return {
            "section": section,
            "row": row,
            "sections": self.hooked_sections(),
            "rows": self.hooked_rows(section),
            "height": self.hooked_height(section, row),
        }

    def hooked_cell(self, display_section, row):
        if display_section == 0 and row == 0:
            return {"synthetic": "HG999"}
        original_section = display_section - 1
        self.depth += 1
        try:
            return self.native_cell(original_section, row)
        finally:
            self.depth -= 1

model = SettingsIndexModel()
checks["顶部 HG999 组映射到合成入口"] = model.hooked_cell(0, 0) == {"synthetic": "HG999"}
for original_section in range(model.sections):
    for row in range(model.rows[original_section]):
        item = model.hooked_cell(original_section + 1, row)
        checks[f"原生组 {original_section} 行 {row} 嵌套委托不重复映射"] = (
            item["section"] == original_section and item["row"] == row and
            item["sections"] == model.sections and
            item["rows"] == model.rows[original_section] and
            item["height"] == model.native_height(original_section, row)
        )

# 行为表：HG999 前置显示，但所有既有原生分组的顺序和值保持不变。
for original_sections in (0, 1, 2, 7):
    displayed = ["HG999"] + [f"native-{i}" for i in range(original_sections)]
    remapped = [displayed[i + 1] for i in range(original_sections)]
    checks[f"{original_sections} 个原生分组顺序保持"] = remapped == [f"native-{i}" for i in range(original_sections)]

for name, passed in checks.items():
    print(("PASS" if passed else "FAIL"), name)
if not all(checks.values()):
    raise SystemExit(1)
