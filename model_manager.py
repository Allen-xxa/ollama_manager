import requests
import json
import os
from PyQt6.QtCore import QObject, pyqtSignal, QRunnable, QThreadPool, QMetaObject, Qt, Q_ARG, pyqtProperty, pyqtSlot

class ModelManager(QObject):
    modelsUpdated = pyqtSignal(list)
    statusUpdated = pyqtSignal(str)
    pullProgressUpdated = pyqtSignal(float, str, str)  # 进度(0-100), 下载速度, 预估时间
    serversUpdated = pyqtSignal()  # 服务器列表更新信号

    def __init__(self):
        super().__init__()
        self._server_address = "localhost"
        self._server_port = "11434"
        self._servers = []
        self.thread_pool = QThreadPool()
        self.config_file = "config.json"
        self.load_config()

    def load_config(self):
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    self._server_address = config.get('server_address', 'localhost')
                    self._server_port = config.get('server_port', '11434')
                    self._servers = config.get('servers', [])
                    # Filter out any empty or invalid server entries
                    self._servers = [server for server in self._servers if all(key in server for key in ['name', 'address', 'port', 'isActive'])]
                    # If server list is empty, add default server
                    if not self._servers:
                        self._servers = [{
                            'name': '本地服务器',
                            'address': self._server_address,
                            'port': self._server_port,
                            'isActive': True
                        }]
                        # Save the configuration with the default server
                        self.save_config()
            except Exception as e:
                print(f"Error loading config: {str(e)}")
                # 加载失败时使用默认配置
                self._server_address = 'localhost'
                self._server_port = '11434'
                self._servers = [{
                    'name': '本地服务器',
                    'address': self._server_address,
                    'port': self._server_port,
                    'isActive': True
                }]
                # Save the default configuration
                self.save_config()
        else:
            # Config file doesn't exist, use default configuration
            self._server_address = 'localhost'
            self._server_port = '11434'
            self._servers = [{
                'name': '本地服务器',
                'address': self._server_address,
                'port': self._server_port,
                'isActive': True
            }]
            # Save the default configuration
            self.save_config()

    def save_config(self):
        config = {
            'server_address': self._server_address,
            'server_port': self._server_port,
            'servers': self._servers
        }
        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"Error saving config: {str(e)}")

    @pyqtProperty(str, constant=True)
    def serverAddress(self):
        return self._server_address

    @pyqtProperty(str, constant=True)
    def serverPort(self):
        return self._server_port

    @pyqtProperty(str, constant=True)
    def apiUrl(self):
        return f"http://{self._server_address}:{self._server_port}/api"

    @pyqtSlot(str)
    def setServerAddress(self, address):
        self._server_address = address
        self.save_config()

    @pyqtSlot(str)
    def setServerPort(self, port):
        self._server_port = port
        self.save_config()

    @pyqtProperty(list, notify=serversUpdated)
    def servers(self):
        return self._servers

    @pyqtSlot(list)
    def setServers(self, servers):
        self._servers = servers
        self.save_config()
        self.serversUpdated.emit()

    @pyqtSlot(str, str, str)
    def addServer(self, name, address, port):
        # 检查是否已存在同名服务器
        for server in self._servers:
            if server['name'] == name:
                return
        
        # 添加新服务器
        new_server = {
            'name': name,
            'address': address,
            'port': port,
            'isActive': False
        }
        self._servers.append(new_server)
        
        # Force a new list reference to ensure QML detects the change
        self._servers = self._servers.copy()
        
        self.save_config()
        self.serversUpdated.emit()
    
    @pyqtSlot(str, str, result=bool)
    def testServerConnection(self, address, port):
        """测试服务器连接（同步方法，不建议直接从UI线程调用）"""
        try:
            response = requests.get(f"http://{address}:{port}/api/tags", timeout=2)
            return response.status_code == 200
        except Exception as e:
            print(f"Error testing server connection: {str(e)}")
            return False
    
    @pyqtSlot(str, str)
    def testServerConnectionAsync(self, address, port):
        """异步测试服务器连接"""
        worker = APICallWorker(self._test_server_connection, address, port)
        self.thread_pool.start(worker)
    
    def _test_server_connection(self, address, port):
        """服务器连接测试的实际实现（在后台线程中执行）"""
        try:
            response = requests.get(f"http://{address}:{port}/api/tags", timeout=2)
            is_connected = response.status_code == 200
        except Exception as e:
            print(f"Error testing server connection: {str(e)}")
            is_connected = False
        
        # 这里可以添加信号来通知UI线程测试结果
        # 暂时不实现，因为QML端的逻辑已经处理了状态显示
    
    @pyqtSlot(int, str, str, str)
    def updateServer(self, index, name, address, port):
        if 0 <= index < len(self._servers):
            self._servers[index]['name'] = name
            self._servers[index]['address'] = address
            self._servers[index]['port'] = port
            # Force a new list reference to ensure QML detects the change
            self._servers = self._servers.copy()
            self.save_config()
            self.serversUpdated.emit()

    @pyqtSlot(int)
    def removeServer(self, index):
        if 0 <= index < len(self._servers):
            self._servers.pop(index)
            # Force a new list reference to ensure QML detects the change
            self._servers = self._servers.copy()
            self.save_config()
            self.serversUpdated.emit()

    @pyqtSlot(int)
    def setActiveServer(self, index):
        if 0 <= index < len(self._servers):
            # 取消所有服务器的活跃状态
            for server in self._servers:
                server['isActive'] = False
            
            # 设置选中的服务器为活跃状态
            active_server = self._servers[index]
            active_server['isActive'] = True
            
            # 更新当前服务器配置
            self._server_address = active_server['address']
            self._server_port = active_server['port']
            
            # Force a new list reference to ensure QML detects the change
            self._servers = self._servers.copy()
            
            self.save_config()
            self.serversUpdated.emit()
    
    @pyqtSlot()
    def getModels(self):
        worker = APICallWorker(self._get_models)
        self.thread_pool.start(worker)

    def _get_models(self):
        try:
            response = requests.get(f"{self.apiUrl}/tags", timeout=2)
            if response.status_code == 200:
                models = response.json().get("models", [])
                # Use Q_ARG to pass the model list
                QMetaObject.invokeMethod(self, "modelsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, models))
                self.statusUpdated.emit("连接成功")
            else:
                self.statusUpdated.emit("连接失败: " + str(response.status_code))
                # Create an empty model list to avoid UI issues
                QMetaObject.invokeMethod(self, "modelsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, []))
        except Exception as e:
            self.statusUpdated.emit("ollama服务器连接失败")
            # Create an empty model list to avoid UI issues
            QMetaObject.invokeMethod(self, "modelsUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(list, []))

    @pyqtSlot(str)
    def pullModel(self, model_name):
        worker = APICallWorker(self._pull_model, model_name)
        self.thread_pool.start(worker)

    def _get_current_model_digest(self, model_name):
        try:
            response = requests.get(f"{self.apiUrl}/tags", timeout=2)
            if response.status_code == 200:
                models = response.json().get("models", [])
                for model in models:
                    if model.get("name") == model_name:
                        return model.get("digest", "")
        except Exception as e:
            print(f"Error getting model digest: {str(e)}")
        return ""

    def _pull_model(self, model_name):
        import time
        try:
            self.statusUpdated.emit(f"检查模型更新: {model_name}")
            
            current_digest = self._get_current_model_digest(model_name)
            if current_digest:
                self.statusUpdated.emit(f"当前模型哈希: {current_digest[:16]}...")
            
            self.statusUpdated.emit(f"拉取模型: {model_name}")
            response = requests.post(f"{self.apiUrl}/pull", json={"name": model_name}, stream=True, timeout=30)
            
            new_digest = None
            is_already_latest = False
            
            for chunk in response.iter_content(chunk_size=1024):
                if chunk:
                    try:
                        data = json.loads(chunk.decode('utf-8'))
                        status = data.get("status", "")
                        digest = data.get("digest", "")
                        
                        if status:
                            if "already up to date" in status.lower() or "already exists" in status.lower():
                                is_already_latest = True
                                self.statusUpdated.emit(f"模型 {model_name} 已是最新版本")
                                return
                            
                            self.statusUpdated.emit(status)
                        
                        if digest:
                            new_digest = digest
                            if current_digest and new_digest == current_digest:
                                is_already_latest = True
                                self.statusUpdated.emit(f"模型 {model_name} 已是最新版本")
                                return
                    except json.JSONDecodeError:
                        pass
            
            if response.status_code == 200:
                if not is_already_latest:
                    self.pullProgressUpdated.emit(100, "0 MB/s", "0s")
                    self.statusUpdated.emit(f"模型 {model_name} 更新成功")
                    self.getModels()
            else:
                self.statusUpdated.emit(f"拉取失败: {response.status_code}")
        except requests.exceptions.Timeout:
            self.statusUpdated.emit(f"拉取模型超时，请检查网络连接")
        except Exception as e:
            self.statusUpdated.emit(f"错误: {str(e)}")
    
    def _format_time(self, seconds):
        """格式化时间为可读格式"""
        if seconds < 60:
            return f"{int(seconds)}s"
        elif seconds < 3600:
            minutes = int(seconds / 60)
            secs = int(seconds % 60)
            return f"{minutes}m {secs}s"
        else:
            hours = int(seconds / 3600)
            minutes = int((seconds % 3600) / 60)
            return f"{hours}h {minutes}m"

    @pyqtSlot(str)
    def deleteModel(self, model_name):
        worker = APICallWorker(self._delete_model, model_name)
        self.thread_pool.start(worker)

    def _delete_model(self, model_name):
        try:
            response = requests.delete(f"{self.apiUrl}/delete", json={"name": model_name}, timeout=2)
            if response.status_code == 200:
                self.statusUpdated.emit(f"Model {model_name} deleted successfully")
                self.getModels()
            else:
                self.statusUpdated.emit(f"Failed to delete model: {response.status_code}")
        except Exception as e:
            self.statusUpdated.emit(f"Error: {str(e)}")

    @pyqtSlot(str, str)
    def createModel(self, model_name, base_model):
        worker = APICallWorker(self._create_model, model_name, base_model)
        self.thread_pool.start(worker)

    def _create_model(self, model_name, base_model):
        try:
            self.statusUpdated.emit(f"Creating model: {model_name}")
            response = requests.post(f"{self.apiUrl}/create", json={"name": model_name, "base": base_model}, timeout=2)
            if response.status_code == 200:
                self.statusUpdated.emit(f"Model {model_name} created successfully")
                self.getModels()
            else:
                self.statusUpdated.emit(f"Failed to create model: {response.status_code}")
        except Exception as e:
            self.statusUpdated.emit(f"Error: {str(e)}")

class APICallWorker(QRunnable):
    def __init__(self, func, *args):
        super().__init__()
        self.func = func
        self.args = args

    def run(self):
        self.func(*self.args)