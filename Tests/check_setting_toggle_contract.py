import argparse
from pathlib import Path
import re
import sys


偏好键 = "video_fullscreen_tab_bar_transparent"


def 读取函数体(源码, 函数名):
    声明 = re.compile(
        r"(?m)^[ \t]*(?:BOOL|void|UITableViewCell\s*\*)\s*"
        + re.escape(函数名)
        + r"\s*\([^;\n]*\)\s*\{"
    )
    命中 = 声明.search(源码)
    if not 命中:
        raise ValueError(f"找不到函数定义：{函数名}")

    起点 = 命中.end() - 1
    深度 = 0
    字符串中 = False
    转义 = False
    for 位置 in range(起点, len(源码)):
        字符 = 源码[位置]
        if 字符串中:
            if 转义:
                转义 = False
            elif 字符 == "\\":
                转义 = True
            elif 字符 == '"':
                字符串中 = False
            continue
        if 字符 == '"':
            字符串中 = True
        elif 字符 == "{":
            深度 += 1
        elif 字符 == "}":
            深度 -= 1
            if 深度 == 0:
                return 源码[起点 + 1 : 位置]
    raise ValueError(f"函数大括号不匹配：{函数名}")


def 加载源码(root):
    路径 = root / "Sources"
    return {
        "开关": (路径 / "AxsHG999FullscreenSetting.m").read_text(encoding="utf-8"),
        "配置": (路径 / "AxsHG999Config.m").read_text(encoding="utf-8"),
        "偏好": (路径 / "AxsHG999Preferences.m").read_text(encoding="utf-8"),
    }


def 源码契约(源码):
    开关 = 源码["开关"]
    配置 = 源码["配置"]
    偏好 = 源码["偏好"]
    读取 = 读取函数体(开关, "axs_hg999_isVideoFullscreenTabBarTransparent")
    保存 = 读取函数体(开关, "axs_hg999_setVideoFullscreenTabBarTransparent")
    创建单元格 = 读取函数体(开关, "axs_hg999_createVideoFullscreenOptionCell")
    写入偏好 = 读取函数体(偏好, "axs_hg999_writePreference")

    键定义 = re.search(
        r'axs_hg999_videoFullscreenTabBarTransparentKey\s*=\s*@"([^\"]+)"', 开关
    )
    return {
        "源码：默认值为关闭": bool(
            键定义
            and 键定义.group(1) == 偏好键
            and re.search(r"defaultValue\s*:\s*@NO", 读取)
            and "axs_hg999_videoFullscreenTabBarTransparentKey" in 读取
        ),
        "源码：setter 写入同一持久化偏好键": bool(
            re.search(
                r"axs_hg999_writePreference\s*\(\s*"
                r"axs_hg999_videoFullscreenTabBarTransparentKey\s*,\s*"
                r"@\(enabled\)\s*,\s*&error\s*\)",
                保存,
                re.S,
            )
            and "NSDataWritingAtomic" in 写入偏好
        ),
        "源码：新快照从偏好读取": "self.snapshot = axs_hg999_readPreferences();" in 配置
        and "dictionaryWithContentsOfFile:path" in 偏好,
        "源码：保存失败时 setter 返回失败": bool(
            re.search(r"if\s*\(\s*!saved\s*\)\s*\{\s*return\s+NO\s*;\s*\}", 保存)
        ),
        "源码：单元格绑定原生 switchChangedCallback": bool(
            re.search(r"cell\.switchChangedCallback\s*=\s*\[\^\(BOOL\s+nextValue\)", 创建单元格)
        ),
        "源码：原生回调把新值交给持久化 setter": bool(
            re.search(
                r"if\s*\(\s*!axs_hg999_setVideoFullscreenTabBarTransparent\(nextValue\)\s*\)",
                创建单元格,
            )
        ),
        "源码：写入失败时恢复 switch UI": "strongCell.rightSwitchOn = !nextValue;" in 创建单元格,
        "源码：不再使用旧式 addTarget 旁路": "addTarget" not in 开关,
    }


class 开关状态模型:
    """只模拟偏好字典与 UI 布尔值，不执行 UIKit 或 Objective-C 代码。"""

    def __init__(self, 持久化存储):
        self.持久化存储 = 持久化存储
        self.开关状态 = bool(持久化存储.get(偏好键, False))

    def 切换(self, 新值, 写入成功=True):
        self.开关状态 = bool(新值)
        if not 写入成功:
            self.开关状态 = not bool(新值)
            return False
        self.持久化存储[偏好键] = bool(新值)
        return True


def 状态模型契约():
    空存储 = {}
    初始 = 开关状态模型(空存储)

    开启存储 = {}
    开启 = 开关状态模型(开启存储)
    开启结果 = 开启.切换(True)
    新读取开启 = 开关状态模型(开启存储)
    开启写入为真 = 开启存储.get(偏好键) is True
    新读取仍为开启 = 新读取开启.开关状态 is True

    关闭结果 = 新读取开启.切换(False)
    新读取关闭 = 开关状态模型(开启存储)

    失败存储 = {}
    失败前 = 开关状态模型(失败存储)
    失败前状态 = 失败前.开关状态
    失败结果 = 失败前.切换(True, 写入成功=False)

    return {
        "模型：空配置默认关闭": 初始.开关状态 is False,
        "模型：开启写入 true 且新读取仍为开启": bool(
            开启结果
            and 开启写入为真
            and 新读取仍为开启
        ),
        "模型：关闭写入 false 且新读取为关闭": bool(
            关闭结果
            and 开启存储.get(偏好键) is False
            and 新读取关闭.开关状态 is False
        ),
        "模型：写入失败恢复 UI 且不改变存储": bool(
            not 失败结果
            and 失败前.开关状态 is 失败前状态
            and 失败前.开关状态 is False
            and 失败存储 == {}
        ),
    }


def main():
    parser = argparse.ArgumentParser(description="检查全屏底栏开关持久化契约")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="HG999 项目根目录",
    )
    参数 = parser.parse_args()
    try:
        源码 = 加载源码(参数.root.resolve())
        检查项 = 源码契约(源码)
    except (OSError, ValueError) as 错误:
        print(f"FAIL 无法检查项目源码：{错误}")
        return 2

    检查项.update(状态模型契约())
    for 名称, 通过 in 检查项.items():
        print(("PASS" if 通过 else "FAIL"), 名称)
    print("说明：状态转换检查是 Python 模型，不是 UIKit／运行时证明。")
    if not all(检查项.values()):
        return 1
    print("GREEN：全部契约检查通过。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
