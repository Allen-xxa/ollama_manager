import sys
import os
import json

# 尝试导入版本信息
try:
    from src import __version__
except ImportError:
    # 如果无法导入，直接从文件中读取
    import importlib.util
    spec = importlib.util.spec_from_file_location("__version__", os.path.join(os.path.dirname(__file__), "__init__.py"))
    version_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(version_module)
    __version__ = version_module.__version__

# 获取应用程序运行目录
def get_app_dir():
    if getattr(sys, 'frozen', False):
        # 打包后的可执行文件
        return os.path.dirname(sys.executable)
    else:
        # 开发模式
        return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 读取debug.json配置文件
def read_debug_config(app_dir):
    """读取debug.json配置文件"""
    debug_file = os.path.join(app_dir, "debug.json")
    debug_mode = False
    
    if os.path.exists(debug_file):
        try:
            with open(debug_file, 'r', encoding='utf-8') as f:
                debug_config = json.load(f)
                debug_mode = bool(debug_config.get('debug', 0))
            print(f"📋 读取debug.json成功，debug模式: {'开启' if debug_mode else '关闭'}")
        except Exception as e:
            print(f"❌ 读取debug.json失败: {str(e)}")
            debug_mode = False
    else:
        # 如果文件不存在，创建默认的debug.json
        default_debug_config = {"debug": 0}
        try:
            with open(debug_file, 'w', encoding='utf-8') as f:
                json.dump(default_debug_config, f, indent=2, ensure_ascii=False)
            print(f"✅ 创建默认debug.json: {debug_file}")
            print(f"📋 默认debug模式: 关闭")
        except Exception as e:
            print(f"❌ 创建debug.json失败: {str(e)}")
    
    return debug_mode

# 获取源代码目录
app_dir = get_app_dir()
src_dir = os.path.join(app_dir, 'src') if getattr(sys, 'frozen', False) else os.path.dirname(os.path.abspath(__file__))

# 读取debug配置
debug_mode = read_debug_config(app_dir)

# 添加源代码目录到 Python 路径
sys.path.insert(0, src_dir)

# 打印调试信息
print("-" * 50)
print("🚀 应用程序启动")
print("-" * 50)
print(f"📦 Ollama Manager version: {__version__}")
print("-" * 50 + "\n")

from PyQt6.QtCore import QUrl, QObject, pyqtSignal, pyqtSlot, Qt
from PyQt6.QtGui import QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine
from model_manager import ModelManager
from dark_title_bar import enable_dark_title_bar
from update_manager import UpdateManager

class MainApplication(QObject):
    def __init__(self):
        super().__init__()
        self.model_manager = ModelManager()
        self.update_manager = UpdateManager(model_manager=self.model_manager)
        self.engine = QQmlApplicationEngine()
        self.engine.rootContext().setContextProperty("modelManager", self.model_manager)
        self.engine.rootContext().setContextProperty("updateManager", self.update_manager)
        self.engine.rootContext().setContextProperty("appVersion", __version__)
        self.engine.rootContext().setContextProperty("debugMode", debug_mode)
        self.engine.quit.connect(QGuiApplication.quit)
        
        self.update_manager.setThreadPool(self.model_manager.thread_pool)

    def load_qml(self, qml_file):
        print("-" * 50)
        print("📄 加载 QML 文件")
        print("-" * 50)
        url = QUrl.fromLocalFile(qml_file)
        
        # 监控 QML 加载错误
        def on_qml_error(errors):
            if errors:
                print("❌ QML 加载错误:")
                for error in errors:
                    print(f"  - {error.toString()}")
                print()
        
        self.engine.warnings.connect(on_qml_error)
        
        self.engine.load(url)
        print("-" * 50 + "\n")

if __name__ == "__main__":
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
    app = QGuiApplication(sys.argv)
    
    # 设置应用程序图标
    icon_path = os.path.join(app_dir, "icon.png")
    if os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))
    
    # 检查目录结构
    
    main_app = MainApplication()
    qml_path = os.path.join(app_dir, "ui", "main.qml")
    main_app.load_qml(qml_path)
    
    if not getattr(sys, 'frozen', False):
        main_app.update_manager.enableHotReload(main_app.engine)
    
    # 检查 QML 是否成功加载
    if not main_app.engine.rootObjects():
        # 尝试直接加载根目录的 main.qml
        alt_qml_path = os.path.join(app_dir, "main.qml")
        if os.path.exists(alt_qml_path):
            main_app.load_qml(alt_qml_path)
        sys.exit(1)
    
    # 尝试启用深色标题栏
    if main_app.engine.rootObjects():
        window = main_app.engine.rootObjects()[0]
        if hasattr(window, 'winId'):
            # 对于QML应用，直接尝试使用窗口对象
            try:
                success = enable_dark_title_bar(window)
            except Exception as e:
                # 尝试获取窗口的winId的其他方法
                try:
                    # 尝试通过QGuiApplication获取顶层窗口
                    from PyQt6.QtGui import QGuiApplication
                    top_level_windows = QGuiApplication.topLevelWindows()
                    if top_level_windows:
                        top_window = top_level_windows[0]
                        if hasattr(top_window, 'winId'):
                            success = enable_dark_title_bar(top_window)
                except Exception as e2:
                    pass
    
    main_app.model_manager.getModels()
    sys.exit(app.exec())