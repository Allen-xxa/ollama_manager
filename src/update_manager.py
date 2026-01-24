import os
import sys
import json
import shutil
import zipfile
import hashlib
import requests
import subprocess
from PyQt6.QtCore import QObject, pyqtSignal, QThread, pyqtSlot, QMetaObject, Qt, Q_ARG, QRunnable, QVariant, pyqtProperty, QUrl
from PyQt6.QtCore import QFileSystemWatcher
from typing import Optional, Dict, Any
from logger import logger


class UpdateWorker(QRunnable):
    def __init__(self, func, *args, **kwargs):
        super().__init__()
        self.func = func
        self.args = args
        self.kwargs = kwargs

    def run(self):
        self.func(*self.args, **self.kwargs)


class UpdateManager(QObject):
    updateAvailable = pyqtSignal('QVariant')
    updateNotAvailable = pyqtSignal()
    updateDownloadProgress = pyqtSignal(float, str, str)
    updateDownloadComplete = pyqtSignal(str)
    updateDownloadFailed = pyqtSignal(str)
    updateInstallProgress = pyqtSignal(float)
    updateInstallComplete = pyqtSignal()
    updateInstallFailed = pyqtSignal(str)
    updateCheckFailed = pyqtSignal(str)
    updateCancelled = pyqtSignal()
    settingsUpdated = pyqtSignal()
    
    @pyqtProperty(str)
    def updateServer(self):
        return self.update_server
    
    @pyqtProperty(int)
    def checkInterval(self):
        return self.check_interval
    
    @pyqtProperty(bool)
    def autoDownload(self):
        return self.auto_download
    
    @pyqtProperty(bool)
    def autoInstall(self):
        return self.auto_install
    
    @pyqtProperty(bool)
    def backupEnabled(self):
        return self.backup_enabled
    
    def __init__(self, model_manager=None, parent=None):
        super().__init__(parent)
        self.model_manager = model_manager
        self.current_version = self._get_current_version()
        self.update_server = ""
        self.check_interval = 86400
        self.auto_download = False
        self.auto_install = False
        self.backup_enabled = True
        self.developer_mode = False
        self.is_downloading = False
        self.is_installing = False
        self.download_cancel_event = None
        self.update_info = None
        self.temp_dir = ""
        self.backup_dir = ""
        self.update_file = ""
        self.thread_pool = None
        
        self._init_directories()
        self._load_config()
        
        self.hot_reload_enabled = False
        self.hot_reload_watcher = None

    def _get_current_version(self) -> str:
        try:
            from src import __version__
            return __version__
        except ImportError:
            try:
                import importlib.util
                spec = importlib.util.spec_from_file_location("__version__", os.path.join(os.path.dirname(__file__), "__init__.py"))
                version_module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(version_module)
                return version_module.__version__
            except:
                return "1.0.0"

    def _init_directories(self):
        if getattr(sys, 'frozen', False):
            self.project_root = os.path.dirname(sys.executable)
        else:
            self.project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        
        self.config_dir = os.path.join(self.project_root, "config")
        self.temp_dir = os.path.join(self.project_root, "temp")
        self.backup_dir = os.path.join(self.project_root, "backup")
        self.update_file = os.path.join(self.temp_dir, "update.zip")
        
        for directory in [self.config_dir, self.temp_dir, self.backup_dir]:
            os.makedirs(directory, exist_ok=True)

    def _load_config(self):
        if self.model_manager and hasattr(self.model_manager, '_settings'):
            settings = self.model_manager._settings
            update_config = settings.get('update', {})
            self.update_server = update_config.get('update_server', 'https://github.com/Allen-xxa/ollama_manager/releases')
            self.check_interval = update_config.get('check_interval', 86400)
            self.auto_download = update_config.get('auto_download', False)
            self.auto_install = update_config.get('auto_install', False)
            self.backup_enabled = update_config.get('backup_enabled', True)
            self.developer_mode = update_config.get('developer_mode', False)
            logger.info("✅ 从config.json加载更新配置成功")
        else:
            self._create_default_config()
    
    def _create_default_config(self):
        self.update_server = "https://github.com/Allen-xxa/ollama_manager/releases"
        self.check_interval = 86400
        self.auto_download = False
        self.auto_install = False
        self.backup_enabled = True
        self.developer_mode = False
        self._save_config()
    
    def _save_config(self):
        if self.model_manager and hasattr(self.model_manager, '_settings'):
            settings = self.model_manager._settings
            settings['update'] = {
                'update_server': self.update_server,
                'check_interval': self.check_interval,
                'auto_download': self.auto_download,
                'auto_install': self.auto_install,
                'backup_enabled': self.backup_enabled,
                'developer_mode': self.developer_mode
            }
            self.model_manager.save_settings()
            logger.info("✅ 更新配置已保存到config.json")
        else:
            config_file = os.path.join(self.config_dir, "update_config.json")
            config = {
                'update_server': self.update_server,
                'check_interval': self.check_interval,
                'auto_download': self.auto_download,
                'auto_install': self.auto_install,
                'backup_enabled': self.backup_enabled,
                'developer_mode': self.developer_mode
            }
            try:
                with open(config_file, 'w', encoding='utf-8') as f:
                    json.dump(config, f, indent=2, ensure_ascii=False)
            except Exception as e:
                logger.error(f"❌ 保存更新配置失败: {str(e)}")

    def setThreadPool(self, thread_pool):
        self.thread_pool = thread_pool

    @pyqtSlot()
    def checkForUpdates(self):
        if not self.update_server:
            self.updateCheckFailed.emit("未配置更新服务器地址")
            return
        
        worker = UpdateWorker(self._check_updates_impl)
        if self.thread_pool:
            self.thread_pool.start(worker)
        else:
            worker.run()

    def _check_updates_impl(self):
        try:
            # 检查update_server是否是本地路径
            is_local_path = (self.update_server and (self.update_server.startswith(('G:', 'g:', 'H:', 'h:', 'C:', 'c:', 'D:', 'd:', 'E:', 'e:', 'F:', 'f:')) or \
                                                   self.update_server.startswith('/') or \
                                                   self.update_server.startswith('\\')))
            
            if self.developer_mode and is_local_path:
                # 开发者模式下且是本地路径，使用本地文件检查
                update_server = os.path.normpath(self.update_server)
                version_file = os.path.join(update_server, 'version.json')
                
                if os.path.exists(version_file):
                    with open(version_file, 'r', encoding='utf-8') as f:
                        remote_version_info = json.load(f)
                        remote_version = remote_version_info.get('version', '')
                        
                        if self._compare_versions(remote_version, self.current_version) > 0:
                            download_url = os.path.join(update_server, f"OllamaManager_{remote_version}_x64.zip")
                            self.update_file = download_url
                            
                            self.update_info = {
                                'version': remote_version,
                                'download_url': download_url,
                                'release_notes': remote_version_info.get('release_notes', ''),
                                'file_size': remote_version_info.get('file_size', 0),
                                'md5': remote_version_info.get('md5', ''),
                                'force_update': remote_version_info.get('force_update', False)
                            }
                            self.updateAvailable.emit(self.update_info)
                        else:
                            QMetaObject.invokeMethod(self, "updateNotAvailable", Qt.ConnectionType.QueuedConnection)
                else:
                    error_msg = f"版本文件不存在: {version_file}"
                    QMetaObject.invokeMethod(self, "updateCheckFailed", Qt.ConnectionType.QueuedConnection,
                                           Q_ARG(str, error_msg))
            elif "github.com" in self.update_server:
                # GitHub模式，使用API检查
                api_url = "https://api.github.com/repos/Allen-xxa/ollama_manager/releases/latest"
                response = requests.get(api_url, timeout=10)
                
                if response.status_code == 200:
                    release_info = response.json()
                    tag_name = release_info.get('tag_name', '')
                    remote_version = tag_name.replace('v', '') if tag_name else ''
                    
                    if self._compare_versions(remote_version, self.current_version) > 0:
                        download_url = f"https://github.com/Allen-xxa/ollama_manager/releases/download/v{remote_version}/OllamaManager_{remote_version}_x64.zip"
                        
                        self.update_info = {
                            'version': remote_version,
                            'download_url': download_url,
                            'release_notes': release_info.get('body', ''),
                            'file_size': 0,
                            'md5': '',
                            'force_update': False
                        }
                        self.updateAvailable.emit(self.update_info)
                    else:
                        QMetaObject.invokeMethod(self, "updateNotAvailable", Qt.ConnectionType.QueuedConnection)
                else:
                    error_msg = f"检查更新失败，状态码: {response.status_code}"
                    QMetaObject.invokeMethod(self, "updateCheckFailed", Qt.ConnectionType.QueuedConnection,
                                           Q_ARG(str, error_msg))
            elif self.update_server and not is_local_path:
                # 远程HTTP服务器模式
                version_url = f"{self.update_server.rstrip('/')}/version.json"
                response = requests.get(version_url, timeout=10)
                
                if response.status_code == 200:
                    remote_version_info = response.json()
                    remote_version = remote_version_info.get('version', '')
                    
                    if self._compare_versions(remote_version, self.current_version) > 0:
                        self.update_info = {
                            'version': remote_version,
                            'download_url': remote_version_info.get('download_url', ''),
                            'release_notes': remote_version_info.get('release_notes', ''),
                            'file_size': remote_version_info.get('file_size', 0),
                            'md5': remote_version_info.get('md5', ''),
                            'force_update': remote_version_info.get('force_update', False)
                        }
                        self.updateAvailable.emit(self.update_info)
                    else:
                        QMetaObject.invokeMethod(self, "updateNotAvailable", Qt.ConnectionType.QueuedConnection)
                else:
                    error_msg = f"检查更新失败，状态码: {response.status_code}"
                    QMetaObject.invokeMethod(self, "updateCheckFailed", Qt.ConnectionType.QueuedConnection,
                                           Q_ARG(str, error_msg))
            else:
                # 没有配置更新服务器或本地路径且开发者模式关闭
                QMetaObject.invokeMethod(self, "updateNotAvailable", Qt.ConnectionType.QueuedConnection)
                logger.info("ℹ️  未配置有效更新服务器")
        except requests.exceptions.Timeout:
            error_msg = "检查更新超时，请检查网络连接"
            QMetaObject.invokeMethod(self, "updateCheckFailed", Qt.ConnectionType.QueuedConnection,
                                   Q_ARG(str, error_msg))
            logger.error(f"❌ {error_msg}")
        except Exception as e:
            error_msg = f"检查更新失败: {str(e)}"
            QMetaObject.invokeMethod(self, "updateCheckFailed", Qt.ConnectionType.QueuedConnection,
                                   Q_ARG(str, error_msg))
            # 使用日志记录器记录错误，而不是print
            pass

    def _compare_versions(self, v1: str, v2: str) -> int:
        def version_tuple(v):
            return tuple(map(int, v.split('.')))
        
        v1_tuple = version_tuple(v1)
        v2_tuple = version_tuple(v2)
        
        if v1_tuple > v2_tuple:
            return 1
        elif v1_tuple < v2_tuple:
            return -1
        else:
            return 0

    @pyqtSlot()
    def downloadUpdate(self):
        if not self.update_info:
            self.updateDownloadFailed.emit("未获取到更新信息")
            return
        
        if self.is_downloading:
            self.updateDownloadFailed.emit("正在下载更新")
            return
        
        self.is_downloading = True
        self.download_cancel_event = False
        
        worker = UpdateWorker(self._download_update_impl)
        if self.thread_pool:
            self.thread_pool.start(worker)
        else:
            worker.run()

    def _download_update_impl(self):
        try:
            if not self.update_info:
                self.updateDownloadFailed.emit("未获取到更新信息")
                return

            download_url = self.update_info.get('download_url', '')
            if not download_url:
                self.updateDownloadFailed.emit("未获取到下载地址")
                return

            logger.info(f"📥 开始下载更新包: {download_url}")

            response = requests.get(download_url, stream=True, timeout=30)
            if response.status_code != 200:
                self.updateDownloadFailed.emit(f"下载失败，状态码: {response.status_code}")
                return

            total_size = int(response.headers.get('content-length', 0))
            downloaded_size = 0
            chunk_size = 8192

            os.makedirs(self.temp_dir, exist_ok=True)
            self.update_file = os.path.join(self.temp_dir, "update.zip")

            with open(self.update_file, 'wb') as f:
                for chunk in response.iter_content(chunk_size=chunk_size):
                    if self.download_cancel_event:
                        self.updateCancelled.emit()
                        if os.path.exists(self.update_file):
                            os.remove(self.update_file)
                        return

                    if chunk:
                        f.write(chunk)
                        downloaded_size += len(chunk)

                        if total_size > 0:
                            progress = (downloaded_size / total_size) * 100
                            progress_mb = downloaded_size / (1024 * 1024)
                            total_mb = total_size / (1024 * 1024)
                            self.updateDownloadProgress.emit(
                                progress,
                                f"{progress_mb:.1f}MB / {total_mb:.1f}MB",
                                f"{progress:.1f}%"
                            )

            logger.info(f"✅ 更新包下载完成: {self.update_file}")
            self.updateDownloadComplete.emit(self.update_file)

        except requests.exceptions.Timeout:
            error_msg = "下载超时，请检查网络连接"
            self.updateDownloadFailed.emit(error_msg)
            # 使用日志记录器记录错误，而不是print
            pass
        except Exception as e:
            error_msg = f"下载失败: {str(e)}"
            self.updateDownloadFailed.emit(error_msg)
            # 使用日志记录器记录错误，而不是print
            pass
        finally:
            self.is_downloading = False

    @pyqtSlot()
    def cancelDownload(self):
        if self.is_downloading:
            self.download_cancel_event = True
            self.updateCancelled.emit()

    @pyqtSlot()
    def installUpdate(self):
        if not self.update_file or not os.path.exists(self.update_file):
            self.updateInstallFailed.emit("更新文件不存在")
            return
        
        if self.is_installing:
            self.updateInstallFailed.emit("正在安装更新")
            return
        
        self.is_installing = True
        
        worker = UpdateWorker(self._install_update_impl, self)
        if self.thread_pool:
            self.thread_pool.start(worker)
        else:
            worker.run()

    def _install_update_impl(self):
        # 安装更新逻辑
        pass

    @pyqtSlot()
    def updateNow(self):
        self.downloadUpdate()

    @pyqtSlot(str, str, str, bool, bool, bool)
    def setUpdateConfig(self, server: str, interval: str, auto_download: bool, 
                       auto_install: bool, backup_enabled: bool):
        self.update_server = server
        self.check_interval = int(interval)
        self.auto_download = auto_download
        self.auto_install = auto_install
        self.backup_enabled = backup_enabled
        self._save_config()
    
    @pyqtSlot(bool)
    def setDeveloperMode(self, enabled: bool):
        self.developer_mode = enabled
        self._save_config()
    
    @pyqtSlot()
    def reloadConfig(self):
        """重新加载配置"""
        self._load_config()
        logger.info("✅ 更新管理器配置已重新加载")

    @pyqtSlot(result='QVariant')
    def getUpdateInfo(self):
        return self.update_info

    @pyqtSlot(result=str)
    def getCurrentVersion(self):
        return self.current_version
    
    @pyqtSlot(result=bool)
    def getDeveloperMode(self):
        return self.developer_mode
    
    def enableHotReload(self, engine):
        if self.hot_reload_enabled:
            return
        
        self.hot_reload_enabled = True
        self.hot_reload_watcher = QFileSystemWatcher()
        
        ui_dir = os.path.join(self.project_root, "ui")
        if os.path.exists(ui_dir):
            self.hot_reload_watcher.addPath(ui_dir)
            
            for root, dirs, files in os.walk(ui_dir):
                for file in files:
                    if file.endswith('.qml'):
                        file_path = os.path.join(root, file)
                        self.hot_reload_watcher.addPath(file_path)
            
            self.hot_reload_watcher.fileChanged.connect(self._on_qml_file_changed)
        
        self.engine = engine

    def _on_qml_file_changed(self, path):
        if self.engine and hasattr(self.engine, 'reload'):
            self.engine.reload()
        elif self.engine and hasattr(self.engine, 'clearComponentCache'):
            self.engine.clearComponentCache()
            # 尝试重新加载主QML文件
            main_qml = os.path.join(self.project_root, "ui", "main.qml")
            if os.path.exists(main_qml):
                self.engine.load(QUrl.fromLocalFile(main_qml))

    def cleanup(self):
        # 清理临时文件
        if os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)
        
        # 清理备份文件
        if os.path.exists(self.backup_dir):
            shutil.rmtree(self.backup_dir)

    def getUpdateStatus(self) -> Dict[str, Any]:
        return {
            'is_downloading': self.is_downloading,
            'is_installing': self.is_installing,
            'update_available': self.update_info is not None
        }

    def getUpdateFileInfo(self) -> Optional[Dict[str, Any]]:
        if self.update_file and os.path.exists(self.update_file):
            return {
                'path': self.update_file,
                'size': os.path.getsize(self.update_file)
            }
        return None

    def getConfig(self) -> Dict[str, Any]:
        return {
            'update_server': self.update_server,
            'check_interval': self.check_interval,
            'auto_download': self.auto_download,
            'auto_install': self.auto_install,
            'backup_enabled': self.backup_enabled,
            'developer_mode': self.developer_mode
        }

    def setConfig(self, config: Dict[str, Any]):
        self.update_server = config.get('update_server', self.update_server)
        self.check_interval = config.get('check_interval', self.check_interval)
        self.auto_download = config.get('auto_download', self.auto_download)
        self.auto_install = config.get('auto_install', self.auto_install)
        self.backup_enabled = config.get('backup_enabled', self.backup_enabled)
        self.developer_mode = config.get('developer_mode', self.developer_mode)
        self._save_config()

    def restartApplication(self):
        import subprocess
        import time
        
        if getattr(sys, 'frozen', False):
            exe_path = sys.executable
        else:
            exe_path = sys.executable
            args = [sys.executable, os.path.join(self.project_root, "src", "main.py")]
        
        subprocess.Popen([exe_path], shell=True)
        
        from PyQt6.QtWidgets import QApplication
        QApplication.quit()

    @pyqtSlot()
    def launchUpdater(self):
        """启动更新程序"""
        try:
            if not self.update_info:
                logger.error("❌ 没有可用的更新信息")
                return

            if not self.update_file or not os.path.exists(self.update_file):
                logger.error(f"❌ 更新文件不存在: {self.update_file}")
                return

            logger.info("🚀 准备启动更新程序")

            if getattr(sys, 'frozen', False):
                updater_exe = os.path.join(self.project_root, "OllamaManagerUpdater.exe")
                main_exe = sys.executable
                
                if not os.path.exists(updater_exe):
                    logger.error(f"❌ 更新程序不存在: {updater_exe}")
                    return
            else:
                # 在开发模式下，使用Python解释器运行updater.py脚本
                updater_script = os.path.join(self.project_root, "src", "updater.py")
                main_exe = os.path.join(self.project_root, "src", "main.py")
                
                if not os.path.exists(updater_script):
                    logger.error(f"❌ 更新程序脚本不存在: {updater_script}")
                    return
                
                updater_exe = [sys.executable, updater_script]

            update_info_file = os.path.join(self.temp_dir, "update_info.json")
            os.makedirs(self.temp_dir, exist_ok=True)

            update_info_data = {
                'version': self.update_info.get('version', ''),
                'update_file': self.update_file,
                'target_dir': self.project_root,
                'main_exe': main_exe,
                'backup_dir': self.backup_dir,
                'md5': self.update_info.get('md5', ''),
                'release_notes': self.update_info.get('release_notes', '')
            }

            with open(update_info_file, 'w', encoding='utf-8') as f:
                json.dump(update_info_data, f, indent=2, ensure_ascii=False)

            logger.info(f"📋 更新信息已写入: {update_info_file}")
            logger.info(f"📋 更新版本: {update_info_data['version']}")
            logger.info(f"📋 更新文件: {update_info_data['update_file']}")
            logger.info(f"📋 目标目录: {update_info_data['target_dir']}")

            # 构建启动命令
            if isinstance(updater_exe, list):
                # 开发模式：updater_exe = [python, script]
                cmd = updater_exe + ['--update-info', update_info_file]
            else:
                # 编译模式：updater_exe = exe_path
                cmd = [updater_exe, '--update-info', update_info_file]
            
            subprocess.Popen(cmd, shell=True)

            logger.info("✅ 更新程序已启动")
            logger.info("🔄 主程序即将退出...")

            from PyQt6.QtWidgets import QApplication
            QApplication.quit()

        except Exception as e:
            logger.error(f"❌ 启动更新程序失败: {str(e)}")