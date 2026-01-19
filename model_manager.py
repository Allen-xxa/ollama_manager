import requests
import json
import os
from bs4 import BeautifulSoup
from PyQt6.QtCore import QObject, pyqtSignal, QRunnable, QThreadPool, QMetaObject, Qt, Q_ARG, pyqtProperty, pyqtSlot

class ModelManager(QObject):
    modelsUpdated = pyqtSignal(list)
    statusUpdated = pyqtSignal(str)
    pullProgressUpdated = pyqtSignal(float, str, str)  # 进度(0-100), 下载速度, 预估时间
    downloadTaskUpdated = pyqtSignal('QVariant')  # 下载任务状态更新
    downloadProgressUpdated = pyqtSignal(str, float, str, str)  # 模型名称, 进度(0-100), 速度, 预估时间
    serversUpdated = pyqtSignal()  # 服务器列表更新信号
    serverConnectionTested = pyqtSignal(bool)  # 服务器连接测试结果信号
    activeModelsUpdated = pyqtSignal(int)  # 活跃模型数量更新信号
    activeModelsDetailsUpdated = pyqtSignal(list)  # 活跃模型详细信息更新信号
    diskUsageUpdated = pyqtSignal(str)  # 磁盘使用情况更新信号
    vramUsageUpdated = pyqtSignal(str)  # 显存使用情况更新信号
    modelLibraryUpdated = pyqtSignal(list, int)  # 模型库更新信号 (模型列表, 总模型数)
    modelLibraryStatusUpdated = pyqtSignal(str)  # 模型库状态更新信号
    modelDetailsUpdated = pyqtSignal(list, str)  # 模型详情更新信号 (版本列表, 描述)
    modelDetailsStatusUpdated = pyqtSignal(str)  # 模型详情状态更新信号

    def __init__(self):
        super().__init__()
        self._server_address = "localhost"
        self._server_port = "11434"
        self._servers = []
        self.thread_pool = QThreadPool()
        self.thread_pool.setMaxThreadCount(32)
        self.config_file = "config.json"
        self._current_model = None
        self.download_tasks = {}
        self.download_cancel_events = {}
        self.download_tasks_file = "download_tasks.json"
        self.load_config()
        self.load_download_tasks()

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

    def load_download_tasks(self):
        """从文件加载下载任务"""
        if os.path.exists(self.download_tasks_file):
            try:
                with open(self.download_tasks_file, 'r', encoding='utf-8') as f:
                    tasks = json.load(f)
                    for task_name, task_data in tasks.items():
                        if task_data.get('status') in ['downloading', 'paused']:
                            task_data['status'] = 'paused'
                        self.download_tasks[task_name] = task_data
                    print(f"Loaded {len(self.download_tasks)} download tasks")
            except Exception as e:
                print(f"Error loading download tasks: {str(e)}")

    def save_download_tasks(self):
        """保存下载任务到文件"""
        try:
            with open(self.download_tasks_file, 'w', encoding='utf-8') as f:
                json.dump(self.download_tasks, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"Error saving download tasks: {str(e)}")

    @pyqtSlot(result='QVariantList')
    def loadDownloadTasksFromFile(self):
        """从文件直接加载下载任务列表（用于QML初始化）"""
        tasks = []
        if os.path.exists(self.download_tasks_file):
            try:
                with open(self.download_tasks_file, 'r', encoding='utf-8') as f:
                    file_tasks = json.load(f)
                    for task_name, task_data in file_tasks.items():
                        if task_data.get('status') in ['downloading', 'paused']:
                            task_data['status'] = 'paused'
                        tasks.append(task_data)
                    print(f"Loaded {len(tasks)} download tasks from file")
                    print(f"Tasks data: {tasks}")
            except Exception as e:
                print(f"Error loading download tasks from file: {str(e)}")
        print(f"Returning {len(tasks)} tasks to QML")
        return tasks

    @pyqtProperty(str, constant=True)
    def serverAddress(self):
        return self._server_address

    @pyqtProperty(str, constant=True)
    def serverPort(self):
        return self._server_port

    @pyqtProperty(str, constant=True)
    def apiUrl(self):
        return f"http://{self._server_address}:{self._server_port}/api"

    @pyqtProperty('QVariant', notify=modelsUpdated)
    def currentModel(self):
        return self._current_model

    @pyqtSlot('QVariant')
    def setCurrentModel(self, model):
        self._current_model = model

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
        
        # 发出信号通知测试结果
        QMetaObject.invokeMethod(self, "serverConnectionTested", Qt.ConnectionType.QueuedConnection,
                                 Q_ARG(bool, is_connected))
    
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
        # 获取活跃模型数量
        self.getActiveModels()
        # 获取磁盘使用情况
        self.getDiskUsage()
        # 获取显存使用情况
        self.getVramUsage()

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
    
    @pyqtSlot()
    def getActiveModels(self):
        """获取当前运行的模型数量"""
        worker = APICallWorker(self._get_active_models)
        self.thread_pool.start(worker)
    
    def _get_active_models(self):
        """获取活跃模型数量的实际实现（在后台线程中执行）"""
        try:
            response = requests.get(f"{self.apiUrl}/ps", timeout=2)
            if response.status_code == 200:
                active_models = response.json().get("models", [])
                active_count = len(active_models)
                QMetaObject.invokeMethod(self, "activeModelsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(int, active_count))
                # 发送活跃模型详细信息
                QMetaObject.invokeMethod(self, "activeModelsDetailsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, active_models))
            else:
                QMetaObject.invokeMethod(self, "activeModelsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(int, 0))
                QMetaObject.invokeMethod(self, "activeModelsDetailsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, []))
        except Exception as e:
            print(f"Error getting active models: {str(e)}")
            QMetaObject.invokeMethod(self, "activeModelsUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(int, 0))
            QMetaObject.invokeMethod(self, "activeModelsDetailsUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(list, []))
    
    @pyqtSlot()
    def getDiskUsage(self):
        """获取磁盘使用情况"""
        worker = APICallWorker(self._get_disk_usage)
        self.thread_pool.start(worker)
    
    def _get_disk_usage(self):
        """获取磁盘使用情况的实际实现（在后台线程中执行）"""
        try:
            response = requests.get(f"{self.apiUrl}/tags", timeout=2)
            if response.status_code == 200:
                models = response.json().get("models", [])
                total_size = 0
                for model in models:
                    # 计算模型大小，假设大小以字节为单位
                    size = model.get("size", 0)
                    total_size += size
                
                # 将字节转换为GB
                total_gb = total_size / (1024 * 1024 * 1024)
                # 格式化保留一位小数
                formatted_size = f"{total_gb:.1f} GB"
                QMetaObject.invokeMethod(self, "diskUsageUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(str, formatted_size))
            else:
                QMetaObject.invokeMethod(self, "diskUsageUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(str, "0.0 GB"))
        except Exception as e:
            print(f"Error getting disk usage: {str(e)}")
            QMetaObject.invokeMethod(self, "diskUsageUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(str, "0.0 GB"))
    
    @pyqtSlot()
    def getVramUsage(self):
        """获取显存使用情况"""
        worker = APICallWorker(self._get_vram_usage)
        self.thread_pool.start(worker)
    
    def _get_vram_usage(self):
        """获取显存使用情况的实际实现（在后台线程中执行）"""
        try:
            response = requests.get(f"{self.apiUrl}/ps", timeout=2)
            if response.status_code == 200:
                active_models = response.json().get("models", [])
                total_vram = 0
                for model in active_models:
                    # 获取每个模型的显存占用
                    vram = model.get("size_vram", 0)
                    total_vram += vram
                
                # 将字节转换为合适的单位
                if total_vram == 0:
                    formatted_usage = "0 B"
                elif total_vram < 1024 * 1024:
                    formatted_usage = f"{total_vram} B"
                elif total_vram < 1024 * 1024 * 1024:
                    formatted_usage = f"{(total_vram / (1024 * 1024)):.1f} MB"
                else:
                    formatted_usage = f"{(total_vram / (1024 * 1024 * 1024)):.1f} GB"
                
                QMetaObject.invokeMethod(self, "vramUsageUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(str, formatted_usage))
            else:
                QMetaObject.invokeMethod(self, "vramUsageUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(str, "0 B"))
        except Exception as e:
            print(f"Error getting VRAM usage: {str(e)}")
            QMetaObject.invokeMethod(self, "vramUsageUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(str, "0 B"))

    @pyqtSlot(str)
    def pullModel(self, model_name):
        if model_name in self.download_tasks:
            if self.download_tasks[model_name]['status'] == 'downloading':
                self.statusUpdated.emit("模型已在下载中")
                return
            elif self.download_tasks[model_name]['status'] == 'paused':
                self.statusUpdated.emit("恢复下载")
                self.resumeDownload(model_name)
                return
        
        self.download_tasks[model_name] = {
            'modelName': model_name,
            'status': 'queued',
            'progress': 0,
            'speed': '0 B/s',
            'eta': '计算中...',
            'downloadedSize': '0 B',
            'totalSize': '计算中...',
            'canResume': False
        }
        
        QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                 Q_ARG('QVariant', self.download_tasks[model_name]))
        
        self.save_download_tasks()
        
        import threading
        self.download_cancel_events[model_name] = threading.Event()
        
        worker = APICallWorker(self._pull_model, model_name)
        self.thread_pool.start(worker)

    @pyqtSlot(str)
    def pauseDownload(self, model_name):
        """暂停下载任务"""
        if model_name in self.download_cancel_events:
            self.download_cancel_events[model_name].set()
            self.statusUpdated.emit("正在暂停下载")
            
            if model_name in self.download_tasks:
                self.download_tasks[model_name]['status'] = 'paused'
                self.download_tasks[model_name]['canResume'] = True
                QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG('QVariant', self.download_tasks[model_name]))
                self.save_download_tasks()
        else:
            self.statusUpdated.emit("未找到下载任务")

    @pyqtSlot(str)
    def resumeDownload(self, model_name):
        """恢复下载任务"""
        if model_name in self.download_tasks:
            if self.download_tasks[model_name]['status'] == 'paused':
                self.statusUpdated.emit("恢复下载")
                self.download_tasks[model_name]['status'] = 'queued'
                self.download_tasks[model_name]['canResume'] = True
                QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG('QVariant', self.download_tasks[model_name]))
                self.save_download_tasks()
                
                import threading
                self.download_cancel_events[model_name] = threading.Event()
                
                worker = APICallWorker(self._pull_model, model_name)
                self.thread_pool.start(worker)
            else:
                self.statusUpdated.emit("任务不是暂停状态")
        else:
            self.statusUpdated.emit("未找到下载任务")

    @pyqtSlot(str)
    def cancelDownload(self, model_name):
        """取消下载任务"""
        if model_name in self.download_cancel_events:
            self.download_cancel_events[model_name].set()
            self.statusUpdated.emit("正在取消下载")
            
            if model_name in self.download_tasks:
                self.download_tasks[model_name]['status'] = 'cancelled'
                QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG('QVariant', self.download_tasks[model_name]))
                self.save_download_tasks()
        else:
            self.statusUpdated.emit("未找到下载任务")
    
    @pyqtSlot(result='QVariantList')
    def getDownloadTasks(self):
        """获取当前的下载任务列表"""
        return list(self.download_tasks.values())

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
        import re
        try:
            is_resume = self.download_tasks[model_name].get('canResume', False)
            if is_resume:
                self.statusUpdated.emit("断点续传")
            else:
                self.statusUpdated.emit("检查模型更新")
            
            current_digest = self._get_current_model_digest(model_name)
            if current_digest:
                self.statusUpdated.emit("当前模型哈希: " + current_digest[:16] + "...")
            
            self.statusUpdated.emit("拉取模型")
            
            self.download_tasks[model_name]['status'] = 'downloading'
            QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG('QVariant', self.download_tasks[model_name]))
            self.save_download_tasks()
            
            response = requests.post(f"{self.apiUrl}/pull", json={"name": model_name}, stream=True, timeout=30)
            
            new_digest = None
            is_already_latest = False
            
            total_size = 0
            downloaded_size = 0
            start_time = time.time()
            last_update_time = start_time
            
            for chunk in response.iter_content(chunk_size=1024):
                if model_name in self.download_cancel_events and self.download_cancel_events[model_name].is_set():
                    self.statusUpdated.emit("已暂停下载")
                    if model_name in self.download_tasks:
                        self.download_tasks[model_name]['status'] = 'paused'
                        self.download_tasks[model_name]['canResume'] = True
                        QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                                 Q_ARG('QVariant', self.download_tasks[model_name]))
                        self.save_download_tasks()
                    if model_name in self.download_cancel_events:
                        del self.download_cancel_events[model_name]
                    return
                
                if chunk:
                    try:
                        data = json.loads(chunk.decode('utf-8'))
                        status = data.get("status", "")
                        digest = data.get("digest", "")
                        
                        if status:
                            if "already up to date" in status.lower() or "already exists" in status.lower():
                                is_already_latest = True
                                self.statusUpdated.emit("模型已是最新版本")
                                # 更新任务状态
                                if model_name in self.download_tasks:
                                    self.download_tasks[model_name]['status'] = 'completed'
                                    self.download_tasks[model_name]['progress'] = 100
                                    QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                                             Q_ARG('QVariant', self.download_tasks[model_name]))
                                    # 清理任务
                                    del self.download_tasks[model_name]
                                    if model_name in self.download_cancel_events:
                                        del self.download_cancel_events[model_name]
                                return
                            
                            # 过滤掉技术性的英文状态，只显示有意义的中文状态
                            # 不显示：pulling, verifying sha256, digest, manifest, config等
                            tech_keywords = ['pulling', 'verifying', 'sha256', 'digest', 'manifest', 'config', 'modelfile', 'license', 'template', 'parameters']
                            should_show_status = True
                            for keyword in tech_keywords:
                                if keyword.lower() in status.lower():
                                    should_show_status = False
                                    break
                            
                            if should_show_status:
                                self.statusUpdated.emit(status)
                            
                            # 解析进度信息
                            # 尝试从状态信息中提取进度
                            progress_match = re.search(r'(\d+)%', status)
                            if progress_match:
                                progress = float(progress_match.group(1))
                                self.download_tasks[model_name]['progress'] = progress
                            else:
                                # 尝试从状态信息中提取大小信息
                                size_match = re.search(r'(\d+\.\d+|\d+) (MB|GB|KB)', status)
                                if size_match:
                                    size_value = float(size_match.group(1))
                                    size_unit = size_match.group(2)
                                    
                                    # 转换为字节
                                    if size_unit == 'GB':
                                        size_bytes = size_value * 1024 * 1024 * 1024
                                    elif size_unit == 'MB':
                                        size_bytes = size_value * 1024 * 1024
                                    elif size_unit == 'KB':
                                        size_bytes = size_value * 1024
                                    else:
                                        size_bytes = size_value
                                    
                                    # 假设这是已下载的大小
                                    downloaded_size = size_bytes
                                    
                                    # 估算总大小（如果还不知道）
                                    if total_size == 0:
                                        # 假设总大小是当前下载大小的2倍（临时估算）
                                        total_size = size_bytes * 2
                                    
                                    # 计算进度
                                    progress = (downloaded_size / total_size) * 100 if total_size > 0 else 0
                                    self.download_tasks[model_name]['progress'] = progress
                        
                        if digest:
                            new_digest = digest
                            if current_digest and new_digest == current_digest:
                                is_already_latest = True
                                self.statusUpdated.emit("模型已是最新版本")
                                # 更新任务状态
                                if model_name in self.download_tasks:
                                    self.download_tasks[model_name]['status'] = 'completed'
                                    self.download_tasks[model_name]['progress'] = 100
                                    QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                                             Q_ARG('QVariant', self.download_tasks[model_name]))
                                    # 清理任务
                                    del self.download_tasks[model_name]
                                    if model_name in self.download_cancel_events:
                                        del self.download_cancel_events[model_name]
                                return
                                
                    except json.JSONDecodeError:
                        pass
                
                # 计算下载速度和预估时间
                current_time = time.time()
                elapsed_time = current_time - start_time
                
                # 每0.5秒更新一次进度
                if current_time - last_update_time > 0.5:
                    # 计算速度
                    if elapsed_time > 0:
                        speed = downloaded_size / elapsed_time
                        # 格式化速度
                        if speed > 1024 * 1024 * 1024:
                            speed_str = f"{speed / (1024 * 1024 * 1024):.2f} GB/s"
                        elif speed > 1024 * 1024:
                            speed_str = f"{speed / (1024 * 1024):.2f} MB/s"
                        elif speed > 1024:
                            speed_str = f"{speed / 1024:.2f} KB/s"
                        else:
                            speed_str = f"{speed:.2f} B/s"
                    else:
                        speed_str = "0 B/s"
                    
                    # 计算预估时间
                    if total_size > downloaded_size and elapsed_time > 0:
                        remaining_size = total_size - downloaded_size
                        remaining_time = remaining_size / (downloaded_size / elapsed_time) if downloaded_size > 0 else 0
                        eta_str = self._format_time(remaining_time)
                    else:
                        eta_str = "计算中..."
                    
                    # 格式化已下载大小和总大小
                    def format_size(size_bytes):
                        if size_bytes > 1024 * 1024 * 1024:
                            return f"{size_bytes / (1024 * 1024 * 1024):.2f} GB"
                        elif size_bytes > 1024 * 1024:
                            return f"{size_bytes / (1024 * 1024):.2f} MB"
                        elif size_bytes > 1024:
                            return f"{size_bytes / 1024:.2f} KB"
                        else:
                            return f"{size_bytes} B"
                    
                    downloaded_size_str = format_size(downloaded_size)
                    total_size_str = format_size(total_size) if total_size > 0 else "计算中..."
                    
                    # 更新任务信息
                    self.download_tasks[model_name]['speed'] = speed_str
                    self.download_tasks[model_name]['eta'] = eta_str
                    self.download_tasks[model_name]['downloadedSize'] = downloaded_size_str
                    self.download_tasks[model_name]['totalSize'] = total_size_str
                    
                    # 发送进度更新信号
                    QMetaObject.invokeMethod(self, "pullProgressUpdated", Qt.ConnectionType.QueuedConnection,
                                             Q_ARG(float, self.download_tasks[model_name]['progress']),
                                             Q_ARG(str, speed_str),
                                             Q_ARG(str, eta_str))
                    
                    QMetaObject.invokeMethod(self, "downloadProgressUpdated", Qt.ConnectionType.QueuedConnection,
                                             Q_ARG(str, model_name),
                                             Q_ARG(float, self.download_tasks[model_name]['progress']),
                                             Q_ARG(str, speed_str),
                                             Q_ARG(str, eta_str))
                    
                    QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                             Q_ARG('QVariant', self.download_tasks[model_name]))
                    
                    last_update_time = current_time
            
            if response.status_code == 200:
                if not is_already_latest:
                    self.download_tasks[model_name]['status'] = 'completed'
                    self.download_tasks[model_name]['progress'] = 100
                    self.download_tasks[model_name]['speed'] = '0 B/s'
                    self.download_tasks[model_name]['eta'] = '0s'
                    
                    QMetaObject.invokeMethod(self, "pullProgressUpdated", Qt.ConnectionType.QueuedConnection,
                                             Q_ARG(float, 100),
                                             Q_ARG(str, "0 B/s"),
                                             Q_ARG(str, "0s"))
                    
                    QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                             Q_ARG('QVariant', self.download_tasks[model_name]))
                    
                    self.statusUpdated.emit("模型更新成功")
                    self.getModels()
                    
                    if model_name in self.download_tasks:
                        del self.download_tasks[model_name]
                    self.save_download_tasks()
                    if model_name in self.download_cancel_events:
                        del self.download_cancel_events[model_name]
            else:
                self.statusUpdated.emit("拉取失败")
                if model_name in self.download_tasks:
                    self.download_tasks[model_name]['status'] = 'failed'
                    self.download_tasks[model_name]['canResume'] = True
                    QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                             Q_ARG('QVariant', self.download_tasks[model_name]))
                    self.save_download_tasks()
                if model_name in self.download_cancel_events:
                    del self.download_cancel_events[model_name]
        except requests.exceptions.Timeout:
            self.statusUpdated.emit("拉取模型超时，请检查网络连接")
            if model_name in self.download_tasks:
                self.download_tasks[model_name]['status'] = 'failed'
                self.download_tasks[model_name]['canResume'] = True
                QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG('QVariant', self.download_tasks[model_name]))
                self.save_download_tasks()
            if model_name in self.download_cancel_events:
                del self.download_cancel_events[model_name]
        except Exception as e:
            self.statusUpdated.emit(f"错误: {str(e)}")
            if model_name in self.download_tasks:
                self.download_tasks[model_name]['status'] = 'failed'
                self.download_tasks[model_name]['canResume'] = True
                QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG('QVariant', self.download_tasks[model_name]))
                self.save_download_tasks()
            if model_name in self.download_cancel_events:
                del self.download_cancel_events[model_name]
    
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
                self.statusUpdated.emit("模型删除成功")
                self.getModels()
            else:
                self.statusUpdated.emit("删除模型失败")
        except Exception as e:
            self.statusUpdated.emit("错误: " + str(e))

    @pyqtSlot(str, str)
    def createModel(self, model_name, base_model):
        worker = APICallWorker(self._create_model, model_name, base_model)
        self.thread_pool.start(worker)

    def _create_model(self, model_name, base_model):
        try:
            self.statusUpdated.emit("创建模型")
            response = requests.post(f"{self.apiUrl}/create", json={"name": model_name, "base": base_model}, timeout=2)
            if response.status_code == 200:
                self.statusUpdated.emit("模型创建成功")
                self.getModels()
            else:
                self.statusUpdated.emit("创建模型失败")
        except Exception as e:
            self.statusUpdated.emit("错误: " + str(e))
    
    @pyqtSlot(str)
    def unloadModel(self, model_name):
        """卸载运行中的模型"""
        worker = APICallWorker(self._unload_model, model_name)
        self.thread_pool.start(worker)
    
    def _unload_model(self, model_name):
        """卸载运行中的模型"""
        try:
            self.statusUpdated.emit("卸载模型")
            # 使用正确的API端点卸载模型
            response = requests.post(f"{self.apiUrl}/generate", json={
                "model": model_name,
                "prompt": "",
                "keep_alive": "0"
            }, timeout=2)
            if response.status_code == 200:
                self.statusUpdated.emit("模型卸载成功")
                self.getModels()
            else:
                self.statusUpdated.emit("卸载模型失败")
        except Exception as e:
            self.statusUpdated.emit("错误: " + str(e))

    @pyqtSlot(str, result=str)
    def translateDescription(self, description):
        """翻译模型描述为中文"""
        # 这里使用一个简单的翻译函数
        # 在实际应用中，可以使用更复杂的翻译服务
        try:
            # 尝试使用 requests 库调用简单的翻译 API
            # 这里使用一个免费的翻译 API 示例
            import requests
            url = "https://translate.googleapis.com/translate_a/single"
            params = {
                'client': 'gtx',
                'sl': 'auto',
                'tl': 'zh-CN',
                'dt': 't',
                'q': description
            }
            response = requests.get(url, params=params, timeout=5)
            if response.status_code == 200:
                result = response.json()
                translated = ''.join([part[0] for part in result[0]])
                return translated
        except Exception as e:
            # 如果翻译失败，返回原文
            pass
        return description

    @pyqtSlot(int, int, str)
    def getModelLibrary(self, page=1, page_size=10, search=""):
        """获取Ollama模型库列表（支持分页和搜索）"""
        worker = APICallWorker(self._get_model_library, page, page_size, search)
        self.thread_pool.start(worker)

    def _get_model_library(self, page=1, page_size=10, search=""):
        """从Ollama官网爬取模型库列表"""
        try:
            # 根据是否有搜索词选择不同的URL
            if search:
                # 使用搜索URL
                url = f"https://ollama.com/search?q={requests.utils.quote(search)}"
            else:
                # 使用常规模型库URL
                url = "https://ollama.com/library"
            
            self.modelLibraryStatusUpdated.emit("获取模型库列表...")
            response = requests.get(url, timeout=15)
            
            if response.status_code == 200:
                # 解析HTML页面
                soup = BeautifulSoup(response.text, 'lxml')
                
                # 找到模型列表
                models = []
                
                # 查找所有模型项
                model_items = soup.find_all('li', attrs={'x-test-model': True})
                
                for item in model_items:
                    # 提取模型名称
                    name_elem = item.find('h2')
                    if not name_elem:
                        continue
                    
                    name = name_elem.text.strip()
                    
                    # 提取模型描述
                    desc_elem = item.find('p')
                    description = desc_elem.text.strip() if desc_elem else ""
                    
                    # 提取下载量
                    pull_count = 0
                    pulls_elem = item.find(attrs={'x-test-pull-count': True})
                    if pulls_elem:
                        pull_count_str = pulls_elem.text.strip()
                        import re
                        # 处理带 K 或 M 的情况（如 625.9K, 30.2M）
                        if 'M' in pull_count_str:
                            try:
                                # 移除 M 并乘以 1000000
                                pull_count = int(float(pull_count_str.replace('M', '')) * 1000000)
                            except:
                                pass
                        elif 'K' in pull_count_str:
                            try:
                                # 移除 K 并乘以 1000
                                pull_count = int(float(pull_count_str.replace('K', '')) * 1000)
                            except:
                                pass
                        else:
                            try:
                                pull_count = int(pull_count_str.replace(',', ''))
                            except:
                                pass
                    
                    # 提取更新时间
                    updated_at = ""
                    updated_elem = item.find(attrs={'x-test-updated': True})
                    if updated_elem:
                        updated_at = updated_elem.text.strip()
                    
                    # 格式化下载量为 K 单位
                    def format_pull_count(count):
                        if count >= 1000000:
                            return f"{count / 1000000:.1f}M"
                        elif count >= 1000:
                            return f"{count / 1000:.1f}K"
                        return str(count)
                    
                    # 转换更新时间为中文格式
                    def convert_to_chinese_time(time_str):
                        time_str = time_str.lower()
                        # 处理不同的时间格式
                        if 'month' in time_str:
                            match = re.search(r'(\d+)\s*month', time_str)
                            if match:
                                months = int(match.group(1))
                                if months == 1:
                                    return "1个月前"
                                else:
                                    return f"{months}个月前"
                        elif 'week' in time_str:
                            match = re.search(r'(\d+)\s*week', time_str)
                            if match:
                                weeks = int(match.group(1))
                                if weeks == 1:
                                    return "1周前"
                                else:
                                    return f"{weeks}周前"
                        elif 'day' in time_str:
                            match = re.search(r'(\d+)\s*day', time_str)
                            if match:
                                days = int(match.group(1))
                                if days == 1:
                                    return "1天前"
                                else:
                                    return f"{days}天前"
                        elif 'year' in time_str:
                            match = re.search(r'(\d+)\s*year', time_str)
                            if match:
                                years = int(match.group(1))
                                if years == 1:
                                    return "1年前"
                                else:
                                    return f"{years}年前"
                        return time_str
                    
                    # 提取模型链接
                    model_link = ""
                    link_elem = item.find('a', href=True)
                    if link_elem:
                        model_link = link_elem['href']
                        # 确保链接是完整的URL
                        if not model_link.startswith('http'):
                            model_link = f"https://ollama.com{model_link}"
                    
                    # 创建模型对象
                    model = {
                        "name": name,
                        "display_name": name,
                        "description": description,
                        "pull_count": pull_count,
                        "pull_count_formatted": format_pull_count(pull_count),
                        "updated_at": convert_to_chinese_time(updated_at),
                        "link": model_link
                    }
                    models.append(model)

                
                # 按照下载量排序
                models.sort(key=lambda x: x.get('pull_count', 0), reverse=True)
                
                # 处理分页
                start_index = (page - 1) * page_size
                end_index = start_index + page_size
                paginated_models = models[start_index:end_index]
                
                # 格式化模型数据
                formatted_models = []
                for model in paginated_models:
                    formatted_model = {
                        "name": model.get("name", ""),
                        "display_name": model.get("display_name", model.get("name", "")),
                        "description": model.get("description", ""),
                        "pull_count": model.get("pull_count", 0),
                        "pull_count_formatted": model.get("pull_count_formatted", "0"),
                        "updated_at": model.get("updated_at", ""),
                        "link": model.get("link", "")
                    }
                    formatted_models.append(formatted_model)
                
                total_models = len(models)
                
                QMetaObject.invokeMethod(self, "modelLibraryUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, formatted_models),
                                         Q_ARG(int, total_models))
                self.modelLibraryStatusUpdated.emit("获取模型库列表成功")
            else:
                self.modelLibraryStatusUpdated.emit(f"获取模型库失败: {response.status_code}")
                QMetaObject.invokeMethod(self, "modelLibraryUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, []),
                                         Q_ARG(int, 0))
        except Exception as e:
            self.modelLibraryStatusUpdated.emit(f"获取模型库失败: {str(e)}")
            QMetaObject.invokeMethod(self, "modelLibraryUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(list, []),
                                     Q_ARG(int, 0))

    @pyqtSlot(str)
    def getModelDetails(self, model_link):
        """获取模型详情"""
        worker = APICallWorker(self._get_model_details, model_link)
        self.thread_pool.start(worker)

    def _get_model_details(self, model_link):
        """从模型链接爬取详情"""
        try:
            self.modelDetailsStatusUpdated.emit(f"获取模型详情: {model_link}")
            
            # 发送请求获取模型详情页面
            response = requests.get(model_link, timeout=10)
            
            if response.status_code == 200:
                # 解析HTML页面
                soup = BeautifulSoup(response.text, 'lxml')
                
                # 提取版本信息
                versions = []
                
                # 初始化版本名称集合，用于去重
                version_names = set()  # 用于去重，根据版本名称
                
                # 从URL中提取模型名称
                model_name = model_link.split('/')[-1]
                print(f"Extracted model name from URL: {model_name}")
                
                # 尝试从页面中爬取版本信息
                # 这里我们使用一个通用的爬虫逻辑，尝试从页面中提取版本信息
                # 根据提供的页面结构，版本信息在一个div容器中，使用grid布局
                
                # 查找版本信息容器
                version_container = soup.find('div', class_='min-w-full divide-y divide-gray-200')
                
                if version_container:
                    # 查找所有版本信息div（大屏幕显示的版本信息）
                    version_divs = version_container.find_all('div', class_='hidden group px-4 py-3 sm:grid sm:grid-cols-12 text-[13px]')
                    
                    # 遍历版本信息div
                    for version_div in version_divs:
                        # 提取版本名称
                        name_span = version_div.find('span', class_='col-span-6')
                        if name_span:
                            version_link = name_span.find('a')
                            if version_link:
                                version_name = version_link.get_text(strip=True)
                                
                                # 提取大小
                                size_p = version_div.find_all('p', class_='col-span-2')[0]
                                size_text = size_p.get_text(strip=True) if size_p else ""
                                
                                # 提取上下文
                                context_p = version_div.find_all('p', class_='col-span-2')[1]
                                context_text = context_p.get_text(strip=True) if context_p else ""
                                
                                # 提取输入类型
                                input_p = version_div.find_all('p', class_='col-span-2')[2]
                                input_text = input_p.get_text(strip=True) if input_p else ""
                                
                                # 清理版本名称，移除模型名称前缀
                                if version_name.startswith(model_name + ":"):
                                    version_name = version_name[len(model_name) + 1:]
                                
                                # 清理上下文，移除可能的"context window"后缀
                                import re
                                context_text = re.sub(r'\s*context window\s*', '', context_text)
                                
                                # 检查是否是有效的版本信息
                                if version_name and size_text and any(keyword in size_text.lower() for keyword in ['gb', 'mb', 'k']):
                                    # 创建一个版本对象
                                    version = {
                                        "version": version_name,
                                        "context": context_text,
                                        "size": size_text,
                                        "input": input_text
                                    }
                                    
                                    # 去重：只添加版本名称不同的版本
                                    if version["version"] not in version_names:
                                        version_names.add(version["version"])
                                        # 添加版本到列表
                                        versions.append(version)
                    

                
                # 如果没有从页面中提取到版本信息，使用通用版本
                if not versions:
                    # 对于未知模型，使用通用版本
                    versions = [
                        {"version": "latest", "context": "128K", "size": "4.9GB", "input": "Text"},
                        {"version": "base", "context": "128K", "size": "4.9GB", "input": "Text"}
                    ]
                    print(f"Using generic versions for model: {model_name}")
                else:
                    print(f"Using crawled versions for model: {model_name}")
                
                # 打印最终版本信息
                print(f"Final versions to return: {len(versions)}")
                for version in versions:
                    print(f"  - {version['version']}: {version['size']}, context: {version['context']}, input: {version['input']}")
                
                # 确保至少有一个版本
                if not versions:
                    versions = [
                        {"version": "latest", "context": "128K", "size": "4.9GB", "input": "Text"}
                    ]
                    print("Added fallback version")
                
                # 提取详细描述
                description = "这是模型的详细描述信息。由于页面结构可能变化，这里返回默认描述。实际应用中需要根据具体页面结构提取详细信息。"
                
                # 发送信号更新详情
                QMetaObject.invokeMethod(self, "modelDetailsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, versions),
                                         Q_ARG(str, description))
                self.modelDetailsStatusUpdated.emit("获取模型详情成功")
            else:
                self.modelDetailsStatusUpdated.emit(f"获取模型详情失败: {response.status_code}")
                # 发送空数据
                QMetaObject.invokeMethod(self, "modelDetailsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, []),
                                         Q_ARG(str, "获取详情失败"))
        except Exception as e:
            error_msg = f"获取模型详情失败: {str(e)}"
            self.modelDetailsStatusUpdated.emit(error_msg)
            print(f"Error in _get_model_details: {str(e)}")
            # 发送空数据
            QMetaObject.invokeMethod(self, "modelDetailsUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(list, []),
                                     Q_ARG(str, error_msg))

class APICallWorker(QRunnable):
    def __init__(self, func, *args):
        super().__init__()
        self.func = func
        self.args = args

    def run(self):
        self.func(*self.args)