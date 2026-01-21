import sys
import os

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

# 获取源代码目录
app_dir = get_app_dir()
src_dir = os.path.join(app_dir, 'src') if getattr(sys, 'frozen', False) else os.path.dirname(os.path.abspath(__file__))

# 添加源代码目录到 Python 路径
sys.path.insert(0, src_dir)

# 打印调试信息
# print(f"App directory: {app_dir}")
# print(f"Src directory: {src_dir}")
# print(f"Python path: {sys.path}")
# print(f"Ollama Manager version: {__version__}")

from PyQt6.QtCore import QUrl, QObject, pyqtSignal, pyqtSlot, Qt
from PyQt6.QtGui import QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine
from model_manager import ModelManager
from dark_title_bar import enable_dark_title_bar

class MainApplication(QObject):
    def __init__(self):
        super().__init__()
        self.model_manager = ModelManager()
        self.engine = QQmlApplicationEngine()
        self.engine.rootContext().setContextProperty("modelManager", self.model_manager)
        self.engine.rootContext().setContextProperty("appVersion", __version__)
        self.engine.quit.connect(QGuiApplication.quit)

    def load_qml(self, qml_file):
        # print(f"Trying to load QML: {qml_file}")
        # print(f"QML file exists: {os.path.exists(qml_file)}")
        
        url = QUrl.fromLocalFile(qml_file)
        # print(f"QML URL: {url}")
        
        # 监控 QML 加载错误
        def on_qml_error(errors):
            # print("QML errors:")
            # for error in errors:
            #     print(f"  - {error.toString()}")
            pass
        
        self.engine.warnings.connect(on_qml_error)
        
        result = self.engine.load(url)
        # print(f"QML load result: {result}")
        # print(f"Root objects: {len(self.engine.rootObjects())}")

if __name__ == "__main__":
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
    app = QGuiApplication(sys.argv)
    
    # 设置应用程序图标
    icon_path = os.path.join(app_dir, "ollama.png")
    # print(f"Icon path: {icon_path}")
    # print(f"Icon exists: {os.path.exists(icon_path)}")
    
    if os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))
    
    # 检查目录结构
    # print(f"Checking directory structure in: {app_dir}")
    # if os.path.exists(app_dir):
    #     print("Files in app directory:")
    #     for item in os.listdir(app_dir):
    #         item_path = os.path.join(app_dir, item)
    #         if os.path.isdir(item_path):
    #             print(f"  [DIR]  {item}")
    #         else:
    #             print(f"  [FILE] {item}")
    
    main_app = MainApplication()
    qml_path = os.path.join(app_dir, "ui", "main.qml")
    main_app.load_qml(qml_path)
    
    # 检查 QML 是否成功加载
    if not main_app.engine.rootObjects():
        # print("ERROR: No root objects created from QML!")
        # 尝试直接加载根目录的 main.qml
        alt_qml_path = os.path.join(app_dir, "main.qml")
        # print(f"Trying alternative QML path: {alt_qml_path}")
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
                # print(f"Dark title bar enabled: {success}")
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
                            # print(f"Dark title bar enabled (top level): {success}")
                except Exception as e2:
                    # print(f"Error enabling dark title bar: {e2}")
                    pass
    
    main_app.model_manager.getModels()
    sys.exit(app.exec())