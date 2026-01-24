import os
import sys
import hashlib
import shutil
import zipfile
import psutil
import time
from typing import Optional, Callable
from logger import logger


def is_process_running(process_name: str) -> bool:
    """检查进程是否正在运行"""
    try:
        for proc in psutil.process_iter(['name']):
            if proc.info['name'] and proc.info['name'].lower() == process_name.lower():
                return True
        return False
    except Exception as e:
        logger.error(f"❌ 检查进程失败: {str(e)}")
        return False


def wait_for_process_exit(process_name: str, timeout: int = 30, check_interval: float = 0.5) -> bool:
    """等待进程退出"""
    start_time = time.time()
    while time.time() - start_time < timeout:
        if not is_process_running(process_name):
            return True
        time.sleep(check_interval)
    return False


def kill_process(process_name: str) -> bool:
    """强制终止进程"""
    try:
        for proc in psutil.process_iter(['name', 'pid']):
            if proc.info['name'] and proc.info['name'].lower() == process_name.lower():
                proc.kill()
                return True
        return False
    except Exception as e:
        logger.error(f"❌ 终止进程失败: {str(e)}")
        return False


def calculate_md5(file_path: str) -> str:
    """计算文件的MD5值"""
    try:
        md5_hash = hashlib.md5()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                md5_hash.update(chunk)
        return md5_hash.hexdigest()
    except Exception as e:
        logger.error(f"❌ 计算MD5失败: {str(e)}")
        return ""


def create_backup(source_dir: str, backup_dir: str, log_callback: Optional[Callable[[str], None]] = None) -> bool:
    """创建备份"""
    try:
        if not os.path.exists(source_dir):
            if log_callback:
                log_callback(f"源目录不存在: {source_dir}")
            return False

        os.makedirs(backup_dir, exist_ok=True)
        
        files_copied = 0
        for item in os.listdir(source_dir):
            source_path = os.path.join(source_dir, item)
            backup_path = os.path.join(backup_dir, item)
            
            if os.path.isfile(source_path):
                shutil.copy2(source_path, backup_path)
                files_copied += 1
            elif os.path.isdir(source_path):
                shutil.copytree(source_path, backup_path, dirs_exist_ok=True)
                files_copied += 1
        
        if log_callback:
            log_callback(f"已备份 {files_copied} 个文件/目录")
        return True
    except Exception as e:
        if log_callback:
            log_callback(f"❌ 备份失败: {str(e)}")
        return False


def extract_zip(zip_path: str, extract_to: str, log_callback: Optional[Callable[[str], None]] = None) -> bool:
    """解压ZIP文件"""
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_to)
        
        if log_callback:
            log_callback(f"已解压到: {extract_to}")
        return True
    except Exception as e:
        if log_callback:
            log_callback(f"❌ 解压失败: {str(e)}")
        return False


def copy_files(source_dir: str, target_dir: str, log_callback: Optional[Callable[[str], None]] = None) -> bool:
    """复制文件到目标目录"""
    try:
        if not os.path.exists(source_dir):
            if log_callback:
                log_callback(f"源目录不存在: {source_dir}")
            return False

        os.makedirs(target_dir, exist_ok=True)
        
        files_copied = 0
        for item in os.listdir(source_dir):
            source_path = os.path.join(source_dir, item)
            target_path = os.path.join(target_dir, item)
            
            if os.path.isfile(source_path):
                shutil.copy2(source_path, target_path)
                files_copied += 1
                if log_callback:
                    log_callback(f"复制文件: {item}")
            elif os.path.isdir(source_dir):
                if os.path.exists(target_path):
                    shutil.rmtree(target_path)
                shutil.copytree(source_path, target_path, dirs_exist_ok=True)
                files_copied += 1
                if log_callback:
                    log_callback(f"复制目录: {item}")
        
        if log_callback:
            log_callback(f"已复制 {files_copied} 个文件/目录")
        return True
    except Exception as e:
        if log_callback:
            log_callback(f"❌ 复制文件失败: {str(e)}")
        return False


def rollback_update(backup_dir: str, target_dir: str, log_callback: Optional[Callable[[str], None]] = None) -> bool:
    """回滚更新"""
    try:
        if not os.path.exists(backup_dir):
            if log_callback:
                log_callback(f"备份目录不存在: {backup_dir}")
            return False

        files_restored = 0
        for item in os.listdir(backup_dir):
            backup_path = os.path.join(backup_dir, item)
            target_path = os.path.join(target_dir, item)
            
            if os.path.isfile(backup_path):
                shutil.copy2(backup_path, target_path)
                files_restored += 1
            elif os.path.isdir(backup_path):
                if os.path.exists(target_path):
                    shutil.rmtree(target_path)
                shutil.copytree(backup_path, target_path, dirs_exist_ok=True)
                files_restored += 1
        
        if log_callback:
            log_callback(f"已恢复 {files_restored} 个文件/目录")
        return True
    except Exception as e:
        if log_callback:
            log_callback(f"❌ 回滚失败: {str(e)}")
        return False


def get_disk_space(path: str) -> tuple[int, int]:
    """获取磁盘空间（总空间，可用空间），单位：字节"""
    try:
        stat = shutil.disk_usage(path)
        return stat.total, stat.free
    except Exception as e:
        logger.error(f"❌ 获取磁盘空间失败: {str(e)}")
        return 0, 0


def check_disk_space(path: str, required_space: int) -> bool:
    """检查磁盘空间是否足够"""
    try:
        _, free_space = get_disk_space(path)
        return free_space >= required_space
    except Exception as e:
        logger.error(f"❌ 检查磁盘空间失败: {str(e)}")
        return False


def get_file_size(file_path: str) -> int:
    """获取文件大小，单位：字节"""
    try:
        return os.path.getsize(file_path)
    except Exception as e:
        logger.error(f"❌ 获取文件大小失败: {str(e)}")
        return 0


def format_size(size_bytes: int) -> str:
    """格式化文件大小"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} TB"
