import ctypes
from ctypes import wintypes

# 定义Windows API常量和结构
class DWMWA(ctypes.c_int):
    USE_IMMERSIVE_DARK_MODE = 20

# 定义Windows API函数
def set_window_attribute(hwnd, attr, value):
    if not isinstance(value, ctypes.c_int):
        value = ctypes.c_int(value)
    return ctypes.windll.dwmapi.DwmSetWindowAttribute(
        hwnd, attr,
        ctypes.byref(value),
        ctypes.sizeof(value)
    )

# 强制窗口使用深色模式
def enable_dark_title_bar(window):
    """
    为Qt窗口启用深色标题栏
    """
    if hasattr(window, 'winId'):
        hwnd = window.winId().__int__()
        result = set_window_attribute(hwnd, DWMWA.USE_IMMERSIVE_DARK_MODE, 1)
        return result == 0
    return False
