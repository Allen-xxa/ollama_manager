import sys
import os
from PyQt6.QtCore import QUrl, QObject, pyqtSignal, pyqtSlot
from PyQt6.QtGui import QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine
from model_manager import ModelManager

class MainApplication(QObject):
    def __init__(self):
        super().__init__()
        self.model_manager = ModelManager()
        self.engine = QQmlApplicationEngine()
        self.engine.rootContext().setContextProperty("modelManager", self.model_manager)
        self.engine.quit.connect(QGuiApplication.quit)

    def load_qml(self, qml_file):
        url = QUrl.fromLocalFile(qml_file)
        self.engine.load(url)

if __name__ == "__main__":
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
    app = QGuiApplication(sys.argv)
    
    # Set application icon
    icon_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ollama.png")
    if os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))
    
    main_app = MainApplication()
    main_app.load_qml("qml/main.qml")
    main_app.model_manager.getModels()
    sys.exit(app.exec())