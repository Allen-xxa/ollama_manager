import os
import sys
import shutil
import zipfile
import json
import time
from typing import Optional, List, Dict, Any
from PyQt6.QtCore import QObject, pyqtSignal


class UpdateInstaller(QObject):
    installStarted = pyqtSignal()
    installProgress = pyqtSignal(float, str)
    installComplete = pyqtSignal()
    installFailed = pyqtSignal(str)
    backupCreated = pyqtSignal(str)
    backupRestored = pyqtSignal()
    rollbackComplete = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.project_root = ""
        self.backup_dir = ""
        self.temp_dir = ""
        self.update_file = ""
        self.extract_dir = ""
        self.is_installing = False
        self.backup_enabled = True
        self.backup_path = ""
        self.install_manifest = None
        self.ignore_patterns = ['*.pyc', '__pycache__', '*.log', '.git']

    def set_project_root(self, path: str):
        self.project_root = path
        self.backup_dir = os.path.join(path, "backup")
        self.temp_dir = os.path.join(path, "temp")
        os.makedirs(self.backup_dir, exist_ok=True)
        os.makedirs(self.temp_dir, exist_ok=True)

    def set_update_file(self, path: str):
        self.update_file = path

    def set_backup_enabled(self, enabled: bool):
        self.backup_enabled = enabled

    def set_ignore_patterns(self, patterns: List[str]):
        self.ignore_patterns = patterns

    def install_update(self, update_file: str = None) -> bool:
        if self.is_installing:
            self.installFailed.emit("正在安装更新")
            return False
        
        if update_file:
            self.set_update_file(update_file)
        
        if not os.path.exists(self.update_file):
            self.installFailed.emit("更新文件不存在")
            return False
        
        self.is_installing = True
        self.installStarted.emit()
        
        try:
            self._extract_update()
            
            self._load_install_manifest()
            
            if self.backup_enabled:
                self._backup_current_version()
            
            self._install_files()
            
            self._cleanup_temp_files()
            
            self.is_installing = False
            self.installComplete.emit()
            return True
            
        except Exception as e:
            self.is_installing = False
            self._cleanup_temp_files()
            self.installFailed.emit(f"安装失败: {str(e)}")
            return False

    def _extract_update(self):
        self.extract_dir = os.path.join(self.temp_dir, "extracted")
        
        if os.path.exists(self.extract_dir):
            shutil.rmtree(self.extract_dir)
        
        os.makedirs(self.extract_dir, exist_ok=True)
        
        self.installProgress.emit(10, "正在解压更新包...")
        
        with zipfile.ZipFile(self.update_file, 'r') as zip_ref:
            zip_ref.extractall(self.extract_dir)
        
        self.installProgress.emit(20, "解压完成")

    def _load_install_manifest(self):
        manifest_file = os.path.join(self.extract_dir, "update_manifest.json")
        
        if os.path.exists(manifest_file):
            with open(manifest_file, 'r', encoding='utf-8') as f:
                self.install_manifest = json.load(f)
        else:
            self.install_manifest = {
                'version': '',
                'files': [],
                'delete_files': [],
                'version_file': 'src/__init__.py'
            }

    def _backup_current_version(self):
        version = self.install_manifest.get('version', 'backup')
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        self.backup_path = os.path.join(self.backup_dir, f"backup_{version}_{timestamp}")
        
        os.makedirs(self.backup_path, exist_ok=True)
        
        self.installProgress.emit(30, "正在备份当前版本...")
        
        files_to_backup = self.install_manifest.get('files', [])
        
        if files_to_backup:
            for file_info in files_to_backup:
                src_path = os.path.join(self.project_root, file_info['path'])
                if os.path.exists(src_path):
                    dest_path = os.path.join(self.backup_path, file_info['path'])
                    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                    if os.path.isdir(src_path):
                        shutil.copytree(src_path, dest_path, 
                                      ignore=shutil.ignore_patterns(*self.ignore_patterns))
                    else:
                        shutil.copy2(src_path, dest_path)
        else:
            ui_dir = os.path.join(self.project_root, "ui")
            if os.path.exists(ui_dir):
                shutil.copytree(ui_dir, os.path.join(self.backup_path, "ui"),
                              ignore=shutil.ignore_patterns(*self.ignore_patterns))
            
            version_file = os.path.join(self.project_root, "src", "__init__.py")
            if os.path.exists(version_file):
                shutil.copy2(version_file, os.path.join(self.backup_path, "__init__.py"))
            
            config_dir = os.path.join(self.project_root, "config")
            if os.path.exists(config_dir):
                shutil.copytree(config_dir, os.path.join(self.backup_path, "config"),
                              ignore=shutil.ignore_patterns(*self.ignore_patterns))
        
        backup_info_file = os.path.join(self.backup_path, "backup_info.json")
        with open(backup_info_file, 'w', encoding='utf-8') as f:
            json.dump({
                'version': version,
                'timestamp': timestamp,
                'backup_path': self.backup_path
            }, f, indent=2, ensure_ascii=False)
        
        self.installProgress.emit(40, "备份完成")
        self.backupCreated.emit(self.backup_path)

    def _install_files(self):
        files_to_install = self.install_manifest.get('files', [])
        
        if files_to_install:
            total_files = len(files_to_install)
            for i, file_info in enumerate(files_to_install):
                progress = 40 + (i / total_files) * 50
                src_path = os.path.join(self.extract_dir, file_info['path'])
                dest_path = os.path.join(self.project_root, file_info['path'])
                
                if os.path.exists(src_path):
                    self.installProgress.emit(progress, f"正在安装: {file_info['path']}")
                    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                    
                    if os.path.isdir(src_path):
                        if os.path.exists(dest_path):
                            shutil.rmtree(dest_path)
                        shutil.copytree(src_path, dest_path)
                    else:
                        shutil.copy2(src_path, dest_path)
        else:
            self.installProgress.emit(50, "正在安装UI文件...")
            ui_dir = os.path.join(self.extract_dir, "ui")
            if os.path.exists(ui_dir):
                dest_ui_dir = os.path.join(self.project_root, "ui")
                if os.path.exists(dest_ui_dir):
                    shutil.rmtree(dest_ui_dir)
                shutil.copytree(ui_dir, dest_ui_dir)
            
            self.installProgress.emit(70, "正在安装版本文件...")
            version_file = os.path.join(self.extract_dir, "__init__.py")
            if os.path.exists(version_file):
                dest_version_file = os.path.join(self.project_root, "src", "__init__.py")
                shutil.copy2(version_file, dest_version_file)
        
        delete_files = self.install_manifest.get('delete_files', [])
        if delete_files:
            self.installProgress.emit(90, "正在清理旧文件...")
            for file_path in delete_files:
                full_path = os.path.join(self.project_root, file_path)
                if os.path.exists(full_path):
                    if os.path.isdir(full_path):
                        shutil.rmtree(full_path)
                    else:
                        os.remove(full_path)
        
        self.installProgress.emit(95, "正在验证安装...")
        self._verify_installation()

    def _verify_installation(self):
        version = self.install_manifest.get('version', '')
        if version:
            version_file = os.path.join(self.project_root, "src", "__init__.py")
            if os.path.exists(version_file):
                with open(version_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if version in content:
                        self.installProgress.emit(100, "安装验证成功")
                        return
        
        self.installProgress.emit(100, "安装完成")

    def _cleanup_temp_files(self):
        if os.path.exists(self.extract_dir):
            shutil.rmtree(self.extract_dir)
        
        if os.path.exists(self.update_file):
            os.remove(self.update_file)

    def restore_backup(self, backup_path: str = None) -> bool:
        if backup_path:
            self.backup_path = backup_path
        
        if not os.path.exists(self.backup_path):
            self.installFailed.emit("备份文件不存在")
            return False
        
        try:
            backup_info_file = os.path.join(self.backup_path, "backup_info.json")
            if os.path.exists(backup_info_file):
                with open(backup_info_file, 'r', encoding='utf-8') as f:
                    backup_info = json.load(f)
                    version = backup_info.get('version', '')
            
            self.installProgress.emit(10, "正在恢复备份...")
            
            for item in os.listdir(self.backup_path):
                if item == "backup_info.json":
                    continue
                
                src_path = os.path.join(self.backup_path, item)
                dest_path = os.path.join(self.project_root, item)
                
                if os.path.exists(dest_path):
                    if os.path.isdir(dest_path):
                        shutil.rmtree(dest_path)
                    else:
                        os.remove(dest_path)
                
                if os.path.isdir(src_path):
                    shutil.copytree(src_path, dest_path)
                else:
                    shutil.copy2(src_path, dest_path)
            
            self.installProgress.emit(100, "备份恢复完成")
            self.backupRestored.emit()
            self.rollbackComplete.emit()
            return True
            
        except Exception as e:
            self.installFailed.emit(f"恢复备份失败: {str(e)}")
            return False

    def get_backup_list(self) -> List[Dict[str, Any]]:
        backups = []
        
        if not os.path.exists(self.backup_dir):
            return backups
        
        for item in os.listdir(self.backup_dir):
            backup_path = os.path.join(self.backup_dir, item)
            if os.path.isdir(backup_path):
                backup_info_file = os.path.join(backup_path, "backup_info.json")
                if os.path.exists(backup_info_file):
                    try:
                        with open(backup_info_file, 'r', encoding='utf-8') as f:
                            backup_info = json.load(f)
                            backups.append({
                                'path': backup_path,
                                'name': item,
                                'version': backup_info.get('version', ''),
                                'timestamp': backup_info.get('timestamp', '')
                            })
                    except:
                        pass
        
        return sorted(backups, key=lambda x: x['timestamp'], reverse=True)

    def delete_backup(self, backup_path: str) -> bool:
        try:
            if os.path.exists(backup_path):
                shutil.rmtree(backup_path)
                return True
        except Exception as e:
            self.installFailed.emit(f"删除备份失败: {str(e)}")
        return False

    def cleanup_old_backups(self, keep_count: int = 3) -> int:
        backups = self.get_backup_list()
        
        if len(backups) <= keep_count:
            return 0
        
        deleted_count = 0
        for backup in backups[keep_count:]:
            if self.delete_backup(backup['path']):
                deleted_count += 1
        
        return deleted_count

    def get_backup_size(self, backup_path: str) -> int:
        total_size = 0
        try:
            for dirpath, dirnames, filenames in os.walk(backup_path):
                for filename in filenames:
                    filepath = os.path.join(dirpath, filename)
                    total_size += os.path.getsize(filepath)
        except:
            pass
        return total_size

    def format_size(self, size_bytes: int) -> str:
        if size_bytes > 1024 * 1024 * 1024:
            return f"{size_bytes / (1024 * 1024 * 1024):.2f} GB"
        elif size_bytes > 1024 * 1024:
            return f"{size_bytes / (1024 * 1024):.2f} MB"
        elif size_bytes > 1024:
            return f"{size_bytes / 1024:.2f} KB"
        return f"{size_bytes} B"

    def is_installing(self) -> bool:
        return self.is_installing

    def get_current_backup_path(self) -> str:
        return self.backup_path

    def validate_update_package(self, update_file: str) -> bool:
        try:
            if not os.path.exists(update_file):
                return False
            
            with zipfile.ZipFile(update_file, 'r') as zip_ref:
                file_list = zip_ref.namelist()
                
                if not file_list:
                    return False
                
                has_manifest = "update_manifest.json" in file_list
                has_ui = any(f.startswith("ui/") for f in file_list)
                
                return has_manifest or has_ui
                
        except:
            return False

    def get_update_info(self, update_file: str) -> Optional[Dict[str, Any]]:
        try:
            if not os.path.exists(update_file):
                return None
            
            temp_extract = os.path.join(self.temp_dir, "info_extract")
            os.makedirs(temp_extract, exist_ok=True)
            
            with zipfile.ZipFile(update_file, 'r') as zip_ref:
                zip_ref.extractall(temp_extract)
            
            manifest_file = os.path.join(temp_extract, "update_manifest.json")
            if os.path.exists(manifest_file):
                with open(manifest_file, 'r', encoding='utf-8') as f:
                    info = json.load(f)
                    info['file_size'] = os.path.getsize(update_file)
                    return info
            
            shutil.rmtree(temp_extract)
            return None
            
        except:
            return None
