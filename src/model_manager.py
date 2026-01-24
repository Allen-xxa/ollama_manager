import requests
import json
import os
import sys
import weakref
import subprocess
import platform
from bs4 import BeautifulSoup
from PyQt6.QtCore import QObject, pyqtSignal, QRunnable, QThreadPool, QMetaObject, Qt, Q_ARG, pyqtProperty, pyqtSlot

def execute_command(command):
    """执行命令并返回结果"""
    try:
        if platform.system() == 'Windows':
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW
            )
        else:
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
        
        stdout, stderr = process.communicate(timeout=30)
        return process.returncode, stdout, stderr
    except Exception as e:
        return -1, "", str(e)

class ModelManager(QObject):
    modelsUpdated = pyqtSignal(list)
    statusUpdated = pyqtSignal(str)
    pullProgressUpdated = pyqtSignal(float, str, str)  # 进度(0-100), 下载速度, 预估时间
    downloadTaskUpdated = pyqtSignal('QVariant')  # 下载任务状态更新
    downloadProgressUpdated = pyqtSignal(str, float, str, str)  # 模型名称, 进度(0-100), 速度, 预估时间
    serversUpdated = pyqtSignal()  # 服务器列表更新信号
    serverConnectionTested = pyqtSignal(bool, float)  # 服务器连接测试结果信号 (连接状态, 延迟毫秒)
    activeModelsUpdated = pyqtSignal(int)  # 活跃模型数量更新信号
    activeModelsDetailsUpdated = pyqtSignal(list)  # 活跃模型详细信息更新信号
    diskUsageUpdated = pyqtSignal(str)  # 磁盘使用情况更新信号
    vramUsageUpdated = pyqtSignal(str)  # 显存使用情况更新信号
    modelLibraryUpdated = pyqtSignal(list, int)  # 模型库更新信号 (模型列表, 总模型数)
    modelLibraryStatusUpdated = pyqtSignal(str)  # 模型库状态更新信号
    modelDetailsUpdated = pyqtSignal(list, str)  # 模型详情更新信号 (版本列表, 描述)
    modelDetailsStatusUpdated = pyqtSignal(str)  # 模型详情状态更新信号
    modelAllVersionsUpdated = pyqtSignal(list)  # 模型所有版本更新信号 (版本列表)
    modelAllVersionsStatusUpdated = pyqtSignal(str)  # 模型所有版本状态更新信号
    settingsUpdated = pyqtSignal()  # 设置更新信号
    unloadModelResult = pyqtSignal(bool, str)  # 模型卸载结果信号 (成功状态, 消息)

    def __init__(self):
        super().__init__()
        self._server_address = "localhost"
        self._server_port = "11434"
        self._servers = []
        self.thread_pool = QThreadPool()
        self.thread_pool.setMaxThreadCount(8)
        
        # 获取项目根目录
        if getattr(sys, 'frozen', False):
            # 打包后的可执行文件
            self.project_root = os.path.dirname(sys.executable)
        else:
            # 开发模式
            self.project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        
        self.config_file = os.path.join(self.project_root, "config", "server.json")
        self.settings_file = os.path.join(self.project_root, "config", "config.json")
        self._current_model = None
        self.download_tasks = {}
        self.download_cancel_events = {}
        self.download_tasks_file = os.path.join(self.project_root, "config", "download_tasks.json")
        self._settings = {}
        self.translation_cache = {}  # 内存缓存，存储翻译结果
        self.load_config()
        self.load_download_tasks()
        self.load_settings()

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
                print(f"❌ Error loading config: {str(e)}\n")
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
            print(f"❌ Error saving config: {str(e)}\n")

    def load_download_tasks(self):
        """从文件加载下载任务"""
        if os.path.exists(self.download_tasks_file):
            try:
                with open(self.download_tasks_file, 'r', encoding='utf-8') as f:
                    tasks = json.load(f)
                    for task_name, task_data in tasks.items():
                        if task_data.get('status') == 'downloading':
                            task_data['status'] = 'paused'
                        self.download_tasks[task_name] = task_data
                    self.save_download_tasks()
            except Exception as e:
                print(f"❌ Error loading download tasks: {str(e)}\n")

    def save_download_tasks(self):
        """保存下载任务到文件"""
        try:
            with open(self.download_tasks_file, 'w', encoding='utf-8') as f:
                json.dump(self.download_tasks, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"❌ Error saving download tasks: {str(e)}\n")

    def load_settings(self):
        """加载设置"""
        if os.path.exists(self.settings_file):
            try:
                with open(self.settings_file, 'r', encoding='utf-8') as f:
                    self._settings = json.load(f)
            except Exception as e:
                print(f"❌ Error loading settings: {str(e)}\n")
                self._settings = {
                    "translation": {
                        "google_translation": True,
                        "ollama_translation": False,
                        "ollama_model": "",
                        "ollama_prompt": "你是一个专业的翻译助手，请将以下内容翻译成中文，保持原文的意思和风格："
                    }
                }
        else:
            self._settings = {
                "translation": {
                    "google_translation": True,
                    "ollama_translation": False,
                    "ollama_model": "",
                    "ollama_prompt": "你是一个专业的翻译助手，请将以下内容翻译成中文，保持原文的意思和风格："
                }
            }
            self.save_settings()

    def save_settings(self):
        """保存设置"""
        try:
            with open(self.settings_file, 'w', encoding='utf-8') as f:
                json.dump(self._settings, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"❌ Error saving settings: {str(e)}\n")
            # 尝试使用备份文件
            try:
                backup_file = self.settings_file + ".backup"
                if os.path.exists(backup_file):
                    with open(backup_file, 'r', encoding='utf-8') as f:
                        self._settings = json.load(f)
            except Exception as backup_error:
                pass

    @pyqtProperty('QVariant', notify=settingsUpdated)
    def settings(self):
        return self._settings

    @pyqtSlot('QVariant')
    def updateSettings(self, settings):
        """更新设置"""
        self._settings.update(settings)
        self.save_settings()
        self.settingsUpdated.emit()

    @pyqtSlot(str, str, result='QVariant')
    def getSetting(self, section, key):
        """获取设置值"""
        if section in self._settings and key in self._settings[section]:
            return self._settings[section][key]
        return None

    @pyqtSlot(str, str, 'QVariant')
    def setSetting(self, section, key, value):
        """设置设置值"""
        if section not in self._settings:
            self._settings[section] = {}
        self._settings[section][key] = value
        self.save_settings()
        self.settingsUpdated.emit()

    @pyqtSlot('QVariant')
    def saveAllSettings(self, settings):
        """批量保存设置"""
        try:
            # 将 QJSValue 转换为 Python 字典
            if hasattr(settings, 'toVariant'):
                self._settings = settings.toVariant()
            else:
                self._settings = settings
            
            # 确保 translation 对象存在
            if 'translation' not in self._settings:
                self._settings['translation'] = {
                    "google_translation": True,
                    "ollama_translation": False,
                    "ollama_model": "",
                    "ollama_prompt": "你是一个专业的翻译助手，请将以下内容翻译成中文，保持原文的意思和风格："
                }
            
            # 验证设置值
            if not isinstance(self._settings.get('translation', {}), dict):
                self._settings['translation'] = {
                    "google_translation": True,
                    "ollama_translation": False,
                    "ollama_model": "",
                    "ollama_prompt": "你是一个专业的翻译助手，请将以下内容翻译成中文，保持原文的意思和风格："
                }
            
            # 处理代理设置
            if 'proxy' not in self._settings:
                self._settings['proxy'] = {
                    "type": "system",
                    "address": ""
                }
            else:
                # 验证代理设置的类型
                proxy_type = self._settings['proxy'].get('type', 'system')
                if proxy_type not in ['none', 'system', 'custom']:
                    self._settings['proxy']['type'] = 'system'
                
                # 如果是自定义代理，且地址为空，使用默认值
                if proxy_type == 'custom':
                    if not self._settings['proxy'].get('address', ''):
                        self._settings['proxy']['address'] = 'http://127.0.0.1:7890'
            
            # 移除根级别的 developer_mode，只保留 update.developer_mode
            if 'developer_mode' in self._settings and 'update' in self._settings and 'developer_mode' in self._settings['update']:
                del self._settings['developer_mode']
            
            self.save_settings()
            self.settingsUpdated.emit()
        except Exception as e:
            print(f"❌ Error saving all settings: {str(e)}\n")
            # 保持原有设置不变
            try:
                self.load_settings()
            except Exception as load_error:
                pass

    @pyqtSlot(result='QVariantList')
    def loadDownloadTasksFromFile(self):
        """从文件直接加载下载任务列表（用于QML初始化）"""
        tasks = []
        if os.path.exists(self.download_tasks_file):
            try:
                with open(self.download_tasks_file, 'r', encoding='utf-8') as f:
                    file_tasks = json.load(f)
                    for task_name, task_data in file_tasks.items():
                        if task_data.get('status') in ['downloading', 'paused', 'queued']:
                            tasks.append(task_data)
                    # print(f"Loaded {len(tasks)} download tasks from file")
                    # print(f"Tasks data: {tasks}")
            except Exception as e:
                # print(f"Error loading download tasks from file: {str(e)}")
                pass
        # print(f"Returning {len(tasks)} tasks to QML")
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
    
    @pyqtSlot(str, str)
    def testServerConnectionAsync(self, address, port):
        """异步测试服务器连接"""
        worker = APICallWorker(self._test_server_connection, address, port)
        self.thread_pool.start(worker)
    
    def _test_server_connection(self, address, port):
        """服务器连接测试的实际实现（在后台线程中执行）"""
        import time
        start_time = time.time()
        try:
            response = requests.get(f"http://{address}:{port}/api/tags", timeout=2)
            is_connected = response.status_code == 200
            latency = (time.time() - start_time) * 1000  # 转换为毫秒
        except Exception as e:
            is_connected = False
            latency = 0
        
        # 发出信号通知测试结果
        QMetaObject.invokeMethod(self, "serverConnectionTested", Qt.ConnectionType.QueuedConnection,
                                 Q_ARG(bool, is_connected),
                                 Q_ARG(float, latency))
    
    @pyqtSlot(int, str, str, str)
    def updateServer(self, index, name, address, port):
        if 0 <= index < len(self._servers):
            is_active_server = self._servers[index]['isActive']
            
            self._servers[index]['name'] = name
            self._servers[index]['address'] = address
            self._servers[index]['port'] = port
            
            # 如果更新的是活跃服务器，同时更新当前服务器地址
            if is_active_server:
                self._server_address = address
                self._server_port = port
            
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
                # 转换模型数据结构，确保包含name和size属性
                formatted_models = []
                for model in models:
                    # 确保模型数据包含必要的属性
                    formatted_model = {
                        "name": model.get("name", ""),
                        "size": model.get("size", 0),
                        "digest": model.get("digest", ""),
                        "details": model.get("details", {}),
                        "modified_at": model.get("modified_at", "")
                    }
                    formatted_models.append(formatted_model)
                # 使用Q_ARG传递模型列表
                QMetaObject.invokeMethod(self, "modelsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, formatted_models))
                self.statusUpdated.emit("连接成功")
            else:
                self.statusUpdated.emit("连接失败: " + str(response.status_code))
                print(f"❌ 连接失败，状态码: {response.status_code}\n")
                # 创建空模型列表以避免UI问题
                QMetaObject.invokeMethod(self, "modelsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, []))
        except Exception as e:
            self.statusUpdated.emit("ollama服务器连接失败")
            # 创建空模型列表以避免UI问题
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
        if model_name in self.download_tasks:
            task_status = self.download_tasks[model_name]['status']
            
            if task_status == 'downloading':
                # 处理下载中的任务
                self.statusUpdated.emit("正在暂停下载")
                # 创建或获取取消事件并设置
                import threading
                if model_name not in self.download_cancel_events:
                    self.download_cancel_events[model_name] = threading.Event()
                self.download_cancel_events[model_name].set()
                
                # 立即更新任务状态为 paused
                self.download_tasks[model_name]['status'] = 'paused'
                self.download_tasks[model_name]['canResume'] = True
                QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG('QVariant', self.download_tasks[model_name]))
                self.save_download_tasks()
                
            elif task_status == 'queued':
                # 处理排队中的任务
                self.statusUpdated.emit("正在暂停下载")
                self.download_tasks[model_name]['status'] = 'paused'
                self.download_tasks[model_name]['canResume'] = True
                QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG('QVariant', self.download_tasks[model_name]))
                self.save_download_tasks()
                # 清理取消事件
                if model_name in self.download_cancel_events:
                    del self.download_cancel_events[model_name]
                    
            elif task_status == 'paused':
                # 任务已经是暂停状态
                self.statusUpdated.emit("任务已经是暂停状态")
            else:
                self.statusUpdated.emit("未找到下载任务")

    @pyqtSlot(str)
    def resumeDownload(self, model_name):
        """恢复下载任务"""
        if model_name in self.download_tasks:
            if self.download_tasks[model_name]['status'] == 'paused':
                self.statusUpdated.emit("恢复下载")
                # 直接将状态设置为 downloading，跳过 queued 状态
                self.download_tasks[model_name]['status'] = 'downloading'
                self.download_tasks[model_name]['canResume'] = True
                QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG('QVariant', self.download_tasks[model_name]))
                self.save_download_tasks()
                
                # 创建新的取消事件（未设置状态，让下载循环正常工作）
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
        if model_name in self.download_tasks:
            # 设置取消事件（如果存在）
            if model_name in self.download_cancel_events:
                self.download_cancel_events[model_name].set()
            
            # 从任务列表中删除
            del self.download_tasks[model_name]
            
            # 清理取消事件
            if model_name in self.download_cancel_events:
                del self.download_cancel_events[model_name]
            
            # 保存任务状态
            self.save_download_tasks()
            
            # 发送任务更新信号（通知前端移除任务）
            # 创建一个临时任务对象用于发送信号
            temp_task = {
                'modelName': model_name,
                'status': 'cancelled'
            }
            QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG('QVariant', temp_task))
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
            print(f"Error getting model digest: {str(e)}\n")
        return ""

    def _pull_model(self, model_name):
        import time
        import re
        # print(f"🔍 正在请求: {self.apiUrl}/pull")
        try:
            is_resume = self.download_tasks[model_name].get('canResume', False)
            if is_resume:
                self.statusUpdated.emit("断点续传")
                # print("⏸️  断点续传")
            else:
                self.statusUpdated.emit("检查模型更新")
                # print("🔍 检查模型更新")
            
            # 检查任务是否已被暂停
            if model_name in self.download_tasks and self.download_tasks[model_name]['status'] == 'paused':
                self.statusUpdated.emit("任务已被暂停")
                # print("⏸️  任务已被暂停")
                return
            
            current_digest = self._get_current_model_digest(model_name)
            if current_digest:
                self.statusUpdated.emit("当前模型哈希: " + current_digest[:16] + "...")
                # print(f"🔐 当前模型哈希: {current_digest[:16]}...")
            
            self.statusUpdated.emit("拉取模型")
            # print("📥 拉取模型")
            
            # 确保任务状态为 downloading
            if model_name in self.download_tasks:
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
            
            # 维护所有层的进度
            layers_progress = {}
            # 全局下载大小（用于速度和预计时间计算）
            global_downloaded_size = 0
            global_total_size = 0
            
            for line in response.iter_lines():
                if model_name in self.download_cancel_events and self.download_cancel_events[model_name].is_set():
                    self.statusUpdated.emit("已暂停下载")
                    # 任务状态已经在 pauseDownload 中更新，这里直接返回
                    if model_name in self.download_cancel_events:
                        del self.download_cancel_events[model_name]
                    return
                
                if line:
                    try:
                        data = json.loads(line.decode('utf-8'))
                        status = data.get("status", "")
                        digest = data.get("digest", "")
                        total = data.get("total", 0)
                        completed = data.get("completed", 0)
                        
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
                            
                            # 使用 Ollama API 的 total 和 completed 字段计算进度
                            if total > 0:
                                # 记录层的进度
                                if digest not in layers_progress:
                                    layers_progress[digest] = {'total': total, 'completed': 0}
                                layers_progress[digest]['total'] = total
                                layers_progress[digest]['completed'] = completed
                                
                                # 计算总进度
                                total_all = sum(layer['total'] for layer in layers_progress.values())
                                completed_all = sum(layer['completed'] for layer in layers_progress.values())
                                overall_progress = (completed_all / total_all * 100) if total_all > 0 else 0
                                
                                # 更新已下载和总大小
                                global_downloaded_size = completed_all
                                global_total_size = total_all
                                
                                self.download_tasks[model_name]['progress'] = overall_progress
                                # 立即发送进度更新信号
                                try:
                                    QMetaObject.invokeMethod(self, "downloadProgressUpdated", Qt.ConnectionType.QueuedConnection,
                                                             Q_ARG(str, model_name),
                                                             Q_ARG(float, overall_progress),
                                                             Q_ARG(str, self.download_tasks[model_name].get('speed', '0 B/s')),
                                                             Q_ARG(str, self.download_tasks[model_name].get('eta', '计算中...')))
                                    QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                                             Q_ARG('QVariant', self.download_tasks[model_name]))
                                    self.save_download_tasks()
                                except RuntimeError as e:
                                    if "wrapped C/C++ object of type ModelManager has been deleted" in str(e):
                                        return
                                    raise
                        
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
                    if elapsed_time > 0 and 'global_downloaded_size' in locals() and global_downloaded_size > 0:
                        speed = global_downloaded_size / elapsed_time
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
                    if 'global_total_size' in locals() and global_total_size > global_downloaded_size and elapsed_time > 0:
                        remaining_size = global_total_size - global_downloaded_size
                        remaining_time = remaining_size / (global_downloaded_size / elapsed_time) if global_downloaded_size > 0 else 0
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
                    
                    downloaded_size_str = format_size(global_downloaded_size) if 'global_downloaded_size' in locals() else format_size(downloaded_size)
                    total_size_str = format_size(global_total_size) if 'global_total_size' in locals() and global_total_size > 0 else format_size(total_size) if total_size > 0 else "计算中..."
                    
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
                    
                    self.save_download_tasks()
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
                    print(f"✅ 模型更新成功: {model_name}\n")
                    self.getModels()
                    
                    if model_name in self.download_tasks:
                        del self.download_tasks[model_name]
                    self.save_download_tasks()
                    if model_name in self.download_cancel_events:
                        del self.download_cancel_events[model_name]
            else:
                self.statusUpdated.emit("拉取失败")
                print(f"❌ 拉取失败: {model_name}\n")
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
            print(f"❌ 拉取模型超时: {model_name}\n")
            if model_name in self.download_tasks:
                self.download_tasks[model_name]['status'] = 'failed'
                self.download_tasks[model_name]['canResume'] = True
                QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG('QVariant', self.download_tasks[model_name]))
                self.save_download_tasks()
            if model_name in self.download_cancel_events:
                del self.download_cancel_events[model_name]
        except Exception as e:
            try:
                self.statusUpdated.emit(f"错误: {str(e)}")
                print(f"❌ 错误: {str(e)}\n")
                if model_name in self.download_tasks:
                    self.download_tasks[model_name]['status'] = 'failed'
                    self.download_tasks[model_name]['canResume'] = True
                    QMetaObject.invokeMethod(self, "downloadTaskUpdated", Qt.ConnectionType.QueuedConnection,
                                             Q_ARG('QVariant', self.download_tasks[model_name]))
                    self.save_download_tasks()
                if model_name in self.download_cancel_events:
                    del self.download_cancel_events[model_name]
            except RuntimeError as re:
                if "wrapped C/C++ object of type ModelManager has been deleted" in str(re):
                    return
                raise
        print("-" * 50 + "\n")
    
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

    @pyqtSlot(str)
    def unloadModel(self, model_name):
        """卸载运行中的模型"""
        worker = APICallWorker(self._unload_model, model_name)
        self.thread_pool.start(worker)
    
    def _unload_model(self, model_name):
        """卸载运行中的模型"""
        try:
            self.statusUpdated.emit("卸载模型")
            
            # 尝试使用专门的卸载端点
            api_success = False
            try:
                # 尝试常见的卸载端点
                endpoints = [
                    f"{self.apiUrl}/unload",
                    f"{self.apiUrl}/models/unload",
                    f"{self.apiUrl}/model/unload"
                ]
                
                for endpoint in endpoints:
                    try:
                        response = requests.post(endpoint, json={
                            "name": model_name
                        }, timeout=2)
                        
                        if response.status_code == 200:
                            self.statusUpdated.emit("模型卸载成功 (API)")
                            self.getModels()
                            api_success = True
                            QMetaObject.invokeMethod(self, "unloadModelResult", Qt.ConnectionType.QueuedConnection,
                                                 Q_ARG(bool, True),
                                                 Q_ARG(str, "模型卸载成功 (API)"))
                            return
                    except:
                        continue
            except Exception as api_error:
                self.statusUpdated.emit(f"尝试专用 API 失败: {str(api_error)}")
            
            # API 失败，尝试当前实现
            if not api_success:
                try:
                    response = requests.post(f"{self.apiUrl}/generate", json={
                        "model": model_name,
                        "prompt": "",
                        "keep_alive": "0"
                    }, timeout=2)
                    
                    if response.status_code == 200:
                        self.statusUpdated.emit("模型卸载成功")
                        self.getModels()
                        QMetaObject.invokeMethod(self, "unloadModelResult", Qt.ConnectionType.QueuedConnection,
                                             Q_ARG(bool, True),
                                             Q_ARG(str, "模型卸载成功"))
                        return
                except Exception as generate_error:
                    self.statusUpdated.emit(f"尝试 generate API 失败: {str(generate_error)}")
            
            # 回退到 CLI
            command = f"ollama rm {model_name}"
            returncode, stdout, stderr = execute_command(command)
            
            if returncode == 0:
                self.statusUpdated.emit("模型卸载成功 (CLI)")
                self.getModels()
                QMetaObject.invokeMethod(self, "unloadModelResult", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(bool, True),
                                         Q_ARG(str, "模型卸载成功 (CLI)"))
            else:
                error_msg = stderr.strip() if stderr else "卸载失败"
                self.statusUpdated.emit(f"卸载模型失败: {error_msg}")
                QMetaObject.invokeMethod(self, "unloadModelResult", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(bool, False),
                                         Q_ARG(str, f"卸载失败: {error_msg}"))
        except Exception as e:
            error_msg = f"错误: {str(e)}"
            self.statusUpdated.emit(error_msg)
            QMetaObject.invokeMethod(self, "unloadModelResult", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(bool, False),
                                     Q_ARG(str, error_msg))
    
    @pyqtSlot(str)
    def unloadModelWithForce(self, model_name):
        """强制卸载运行中的模型"""
        worker = APICallWorker(self._unload_model_with_force, model_name)
        self.thread_pool.start(worker)
    
    def _unload_model_with_force(self, model_name):
        """强制卸载运行中的模型"""
        try:
            self.statusUpdated.emit("强制卸载模型")
            
            # 直接使用 CLI 强制卸载
            command = f"ollama rm --force {model_name}"
            returncode, stdout, stderr = execute_command(command)
            
            if returncode == 0:
                self.statusUpdated.emit("模型强制卸载成功")
                self.getModels()
                QMetaObject.invokeMethod(self, "unloadModelResult", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(bool, True),
                                         Q_ARG(str, "模型强制卸载成功"))
            else:
                error_msg = stderr.strip() if stderr else "强制卸载失败"
                self.statusUpdated.emit(f"强制卸载模型失败: {error_msg}")
                QMetaObject.invokeMethod(self, "unloadModelResult", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(bool, False),
                                         Q_ARG(str, f"强制卸载失败: {error_msg}"))
        except Exception as e:
            error_msg = f"错误: {str(e)}"
            self.statusUpdated.emit(error_msg)
            QMetaObject.invokeMethod(self, "unloadModelResult", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(bool, False),
                                     Q_ARG(str, error_msg))
    
    @pyqtSlot(str, result=bool)
    def isModelLoaded(self, model_name):
        """检查模型是否正在运行"""
        try:
            response = requests.get(f"{self.apiUrl}/ps", timeout=2)
            if response.status_code == 200:
                active_models = response.json().get("models", [])
                for model in active_models:
                    if model.get("name") == model_name:
                        return True
            return False
        except:
            return False

    @pyqtSlot(str, result=str)
    def translateDescription(self, description):
        """翻译模型描述为中文"""
        try:
            # 检查缓存
            cache_key = description.strip()
            if cache_key in self.translation_cache:
                return self.translation_cache[cache_key]
            
            # 获取翻译设置
            translation_settings = self._settings.get("translation", {})
            use_ollama = translation_settings.get("ollama_translation", False)
            use_google = translation_settings.get("google_translation", True)
            
            # 优先使用 Ollama 翻译
            if use_ollama:
                ollama_model = translation_settings.get("ollama_model", "")
                ollama_prompt = translation_settings.get("ollama_prompt", "你是一个专业的翻译助手，请将以下内容翻译成中文，保持原文的意思和风格：")
                
                if ollama_model:
                    max_retries = 3
                    retry_count = 0
                    
                    while retry_count < max_retries:
                        try:
                            # 使用 Ollama 模型进行翻译
                            translate_prompt = f"{ollama_prompt}\n\n{description}"
                            
                            # 优化请求参数
                            response = requests.post(f"{self.apiUrl}/generate", json={
                                "model": ollama_model,
                                "prompt": translate_prompt,
                                "stream": False,
                                "temperature": 0.3,  # 降低随机性，提高翻译准确性
                                "stop": ["\n\n"]  # 设置停止词
                            }, timeout=15)  # 增加超时时间到 15 秒
                            
                            if response.status_code == 200:
                                result = response.json()
                                translated = result.get("response", "").strip()
                                
                                # 后处理：清理翻译结果
                                if translated:
                                    # 移除可能的前缀，如"翻译："、"答案："等
                                    clean_translated = translated.replace("翻译：", "").replace("答案：", "").strip()
                                    # 确保只返回翻译结果，移除与原文重复的内容
                                    if clean_translated and clean_translated != description:
                                        # 存储到缓存
                                        self.translation_cache[cache_key] = clean_translated
                                        return clean_translated
                            
                            # 重试逻辑
                            retry_count += 1
                            if retry_count < max_retries:
                                import time
                                time.sleep(1)  # 短暂延迟后重试
                                
                        except requests.exceptions.Timeout:
                            retry_count += 1
                            if retry_count < max_retries:
                                import time
                                time.sleep(1)
                        except requests.exceptions.ConnectionError:
                            break  # 连接错误不再重试
                        except Exception:
                            retry_count += 1
                            if retry_count < max_retries:
                                import time
                                time.sleep(1)
            
            # 使用 Google 翻译作为备选
            if use_google:
                try:
                    url = "https://translate.googleapis.com/translate_a/single"
                    params = {
                        'client': 'gtx',
                        'sl': 'auto',
                        'tl': 'zh-CN',
                        'dt': 't',
                        'q': description
                    }
                    response = requests.get(url, params=params, timeout=10)  # 增加超时时间
                    if response.status_code == 200:
                        result = response.json()
                        translated = ''.join([part[0] for part in result[0]])
                        # 存储到缓存
                        if translated and translated != description:
                            self.translation_cache[cache_key] = translated
                        return translated
                except Exception:
                    pass
        except Exception as e:
            pass
        return description

    @pyqtSlot()
    def clearTranslationCache(self):
        """清除翻译缓存"""
        cache_size = len(self.translation_cache)
        self.translation_cache.clear()

    @pyqtSlot(result=int)
    def getTranslationCacheSize(self):
        """获取翻译缓存大小"""
        return len(self.translation_cache)

    # 添加翻译完成信号
    translationCompleted = pyqtSignal(str, str)  # 原文, 翻译结果

    @pyqtSlot(str)
    def translateDescriptionAsync(self, description):
        """异步翻译模型描述为中文"""
        worker = APICallWorker(self._translate_description_async, description)
        self.thread_pool.start(worker)

    def _translate_description_async(self, description):
        """异步翻译的实际实现（在后台线程中执行）"""
        translated = self.translateDescription(description)
        # 发出翻译完成信号
        QMetaObject.invokeMethod(self, "translationCompleted", Qt.ConnectionType.QueuedConnection,
                                 Q_ARG(str, description),
                                 Q_ARG(str, translated))

    @pyqtSlot(str)
    def removeFromTranslationCache(self, description):
        """从翻译缓存中移除指定内容"""
        cache_key = description.strip()
        if cache_key in self.translation_cache:
            del self.translation_cache[cache_key]
            # print(f"Removed from translation cache: {cache_key[:50]}...")

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
                # 对于前端的loadModels调用（page=1, page_size=100），返回所有模型
                # 这样前端可以在本地进行分页
                if page == 1 and page_size >= 100:
                    # 返回所有模型，不分页
                    paginated_models = models
                else:
                    # 正常分页
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

    @pyqtSlot(str)
    def getModelAllVersions(self, model_name):
        """获取模型的所有版本"""
        worker = APICallWorker(self._get_model_all_versions, model_name)
        self.thread_pool.start(worker)

    def _get_model_all_versions(self, model_name):
        """从Ollama官网爬取模型的所有版本"""
        try:
            # 构建所有版本页面的URL
            url = f"https://ollama.com/library/{model_name}/tags"
            
            self.modelAllVersionsStatusUpdated.emit(f"获取所有版本: {model_name}")
            response = requests.get(url, timeout=15)
            
            if response.status_code == 200:
                # 解析HTML页面
                soup = BeautifulSoup(response.text, 'lxml')
                
                # 提取版本信息
                versions = []
                
                # 初始化版本名称集合，用于去重
                version_names = set()  # 用于去重，根据版本名称
                
                # 查找版本信息容器
                version_container = soup.find('div', class_='min-w-full divide-y divide-gray-200')
                
                if version_container:
                    # 查找所有版本信息div
                    version_divs = version_container.find_all('div', class_='group px-4 py-3')
                    
                    # 遍历版本信息div
                    for version_div in version_divs:
                        # 查找版本名称
                        version_name = None
                        
                        # 尝试从桌面端显示的版本信息中提取
                        desktop_version_div = version_div.find('div', class_='hidden md:flex')
                        if desktop_version_div:
                            version_link = desktop_version_div.find('a')
                            if version_link:
                                version_name = version_link.get_text(strip=True)
                        else:
                            # 尝试从移动端显示的版本信息中提取
                            mobile_version_link = version_div.find('a', class_='md:hidden')
                            if mobile_version_link:
                                version_span = mobile_version_link.find('span', class_='group-hover:underline')
                                if version_span:
                                    version_name = version_span.get_text(strip=True)
                        
                        if version_name:
                            # 从版本名称中提取版本号（去掉模型名前缀）
                            if version_name.startswith(model_name + ":"):
                                version = version_name[len(model_name) + 1:]
                            else:
                                version = version_name
                            
                            # 提取大小
                            size = "未知"
                            size_p = version_div.find('p', class_='col-span-2')
                            if size_p:
                                size = size_p.get_text(strip=True)
                            else:
                                # 尝试从移动端信息中提取
                                mobile_info = version_div.find('div', class_='flex flex-col text-neutral-500 text-[13px]')
                                if mobile_info:
                                    info_text = mobile_info.get_text(strip=True)
                                    import re
                                    size_match = re.search(r'(\d+\.\d+GB)', info_text)
                                    if size_match:
                                        size = size_match.group(1)
                            
                            # 提取上下文
                            context = "未知"
                            context_p = version_div.find_all('p', class_='col-span-2')
                            if len(context_p) > 1:
                                context = context_p[1].get_text(strip=True)
                            else:
                                # 尝试从移动端信息中提取
                                mobile_info = version_div.find('div', class_='flex flex-col text-neutral-500 text-[13px]')
                                if mobile_info:
                                    info_text = mobile_info.get_text(strip=True)
                                    import re
                                    context_match = re.search(r'(\d+K) context window', info_text)
                                    if context_match:
                                        context = context_match.group(1)
                            
                            # 提取输入类型
                            input_type = "Text"
                            input_div = version_div.find('div', class_='col-span-2 text-neutral-500 text-[13px]')
                            if input_div:
                                input_type = input_div.get_text(strip=True)
                            else:
                                # 尝试从移动端信息中提取
                                mobile_info = version_div.find('div', class_='flex flex-col text-neutral-500 text-[13px]')
                                if mobile_info:
                                    info_text = mobile_info.get_text(strip=True)
                                    if 'Text input' in info_text:
                                        input_type = "Text"
                            
                            # 清理上下文，移除可能的"context window"后缀
                            import re
                            context = re.sub(r'\s*context window\s*', '', context)
                            
                            # 检查是否是有效的版本信息
                            if version and size and any(keyword in size.lower() for keyword in ['gb', 'mb', 'k']):
                                # 创建一个版本对象
                                version_obj = {
                                    "version": version,
                                    "context": context,
                                    "size": size,
                                    "input": input_type
                                }
                                
                                # 去重：只添加版本名称不同的版本
                                if version_obj["version"] not in version_names:
                                    version_names.add(version_obj["version"])
                                    # 添加版本到列表
                                    versions.append(version_obj)
                
                # 如果没有从页面中提取到版本信息，使用通用版本
                if not versions:
                    # 对于未知模型，使用通用版本
                    versions = [
                        {"version": "latest", "context": "128K", "size": "4.9GB", "input": "Text"}
                    ]
                
                # 确保至少有一个版本
                if not versions:
                    versions = [
                        {"version": "latest", "context": "128K", "size": "4.9GB", "input": "Text"}
                    ]
                
                # 发送信号更新所有版本
                QMetaObject.invokeMethod(self, "modelAllVersionsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, versions))
                self.modelAllVersionsStatusUpdated.emit("获取所有版本成功")
            else:
                self.modelAllVersionsStatusUpdated.emit(f"获取所有版本失败: {response.status_code}")
                # 发送空数据
                QMetaObject.invokeMethod(self, "modelAllVersionsUpdated", Qt.ConnectionType.QueuedConnection,
                                         Q_ARG(list, []))
        except Exception as e:
            error_msg = f"获取所有版本失败: {str(e)}"
            self.modelAllVersionsStatusUpdated.emit(error_msg)
            # 发送空数据
            QMetaObject.invokeMethod(self, "modelAllVersionsUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(list, []))

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
                # print(f"Extracted model name from URL: {model_name}")
                
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
                    # print(f"Using generic versions for model: {model_name}")
                else:
                    # print(f"Using crawled versions for model: {model_name}")
                    pass
                
                # 打印最终版本信息
                # print(f"Final versions to return: {len(versions)}")
                # for version in versions:
                #     print(f"  - {version['version']}: {version['size']}, context: {version['context']}, input: {version['input']}")
                
                # 确保至少有一个版本
                if not versions:
                    versions = [
                        {"version": "latest", "context": "128K", "size": "4.9GB", "input": "Text"}
                    ]
                    # print("Added fallback version")
                
                # 提取详细描述 - 从README区域爬取
                description = self._extract_readme_content(soup, model_link)
                
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
            # 发送空数据
            QMetaObject.invokeMethod(self, "modelDetailsUpdated", Qt.ConnectionType.QueuedConnection,
                                     Q_ARG(list, []),
                                     Q_ARG(str, error_msg))

    def _extract_readme_content(self, soup, model_link):
        """从模型详情页面提取README内容，保持原始HTML格式"""
        try:
            # 尝试多种可能的README容器选择器
            readme_selectors = [
                'article',
                'div.markdown-body',
                'div[x-test-readme]',
                'div.prose',
                'div.readme',
                'main > div > div',
                '.content',
                'section'
            ]
            
            readme_content = None
            for selector in readme_selectors:
                readme_content = soup.select_one(selector)
                if readme_content:
                    break
            
            if not readme_content:
                # 如果找不到特定容器，尝试查找包含大量文本的div
                all_divs = soup.find_all('div')
                for div in all_divs:
                    text = div.get_text(strip=True)
                    if len(text) > 200:  # 假设README至少有200个字符
                        readme_content = div
                        break
            
            if readme_content:
                # 提取HTML内容
                html_content = str(readme_content)
                
                # 处理图片链接
                html_content = self._process_image_links(html_content, model_link)
                
                # 清理不需要的元素
                html_content = self._clean_html_content(html_content)
                
                return html_content
            else:
                return "未找到模型描述信息"
                
        except Exception as e:
            # print(f"Error extracting readme content: {str(e)}")
            return f"提取描述信息时出错: {str(e)}"
    
    def _process_image_links(self, html_content, model_link):
        """处理HTML中的图片链接，将相对路径转换为绝对路径"""
        try:
            from bs4 import BeautifulSoup
            soup = BeautifulSoup(html_content, 'lxml')
            
            # 获取基础URL
            base_url = "https://ollama.com"
            if model_link and not model_link.startswith('http'):
                base_url = "https://ollama.com"
            elif model_link:
                # 从模型链接中提取基础路径
                parts = model_link.split('/')
                if len(parts) > 3:
                    base_url = '/'.join(parts[:3])
            
            # 处理所有图片标签
            for img in soup.find_all('img'):
                src = img.get('src', '')
                if src:
                    # 处理相对路径
                    if src.startswith('/'):
                        img['src'] = base_url + src
                    elif not src.startswith('http'):
                        img['src'] = base_url + '/' + src
                    
                    # 移除可能存在的固定宽高属性
                    if 'width' in img.attrs:
                        del img['width']
                    if 'height' in img.attrs:
                        del img['height']
                    if 'style' in img.attrs:
                        del img['style']
                    
                    # 添加自适应图片属性
                    img['width'] = '100%'
                    img['style'] = 'max-width: 100%; height: auto; display: block; margin: 10px 0;'
            
            # 处理所有链接
            for a in soup.find_all('a'):
                href = a.get('href', '')
                if href:
                    if href.startswith('/'):
                        a['href'] = base_url + href
                    elif not href.startswith('http') and not href.startswith('#'):
                        a['href'] = base_url + '/' + href
            
            return str(soup)
            
        except Exception as e:
            # print(f"Error processing image links: {str(e)}")
            return html_content
    
    def _clean_html_content(self, html_content):
        """清理HTML内容，移除不需要的元素"""
        try:
            from bs4 import BeautifulSoup
            soup = BeautifulSoup(html_content, 'lxml')
            
            # 移除script和style标签
            for tag in soup.find_all(['script', 'style', 'noscript']):
                tag.decompose()
            
            # 移除导航、页脚等不需要的元素
            unwanted_classes = ['nav', 'navigation', 'footer', 'header', 'sidebar', 'menu', 'breadcrumb']
            for class_name in unwanted_classes:
                for element in soup.find_all(class_=class_name):
                    element.decompose()
            
            # 移除带有特定属性的元素
            for element in soup.find_all(attrs={'role': 'navigation'}):
                element.decompose()
            
            return str(soup)
            
        except Exception as e:
            # print(f"Error cleaning HTML content: {str(e)}")
            return html_content

class APICallWorker(QRunnable):
    def __init__(self, func, *args):
        super().__init__()
        self.func = func
        self.args = args
        # 获取第一个参数作为可能的ModelManager实例
        self.manager_ref = None
        if args and hasattr(args[0], '__class__') and args[0].__class__.__name__ == 'ModelManager':
            self.manager_ref = weakref.ref(args[0])

    def run(self):
        # 检查ModelManager实例是否仍然存在
        if self.manager_ref and not self.manager_ref():
            return  # 对象已删除，直接返回
        
        try:
            self.func(*self.args)
        except RuntimeError as e:
            # 捕获对象已删除的错误
            if "wrapped C/C++ object of type ModelManager has been deleted" in str(e):
                return
            raise