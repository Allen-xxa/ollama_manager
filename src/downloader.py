import os
import time
import hashlib
import requests
from typing import Optional, Callable
from PyQt6.QtCore import QObject, pyqtSignal, QThread


class UpdateDownloader(QObject):
    downloadStarted = pyqtSignal(str)
    downloadProgress = pyqtSignal(float, str, str)
    downloadComplete = pyqtSignal(str)
    downloadFailed = pyqtSignal(str)
    downloadCancelled = pyqtSignal()
    downloadPaused = pyqtSignal()
    downloadResumed = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.download_url = ""
        self.save_path = ""
        self.file_size = 0
        self.downloaded_size = 0
        self.chunk_size = 8192
        self.is_downloading = False
        self.is_paused = False
        self.cancel_event = None
        self.temp_file = ""
        self.progress_callback = None
        self.speed_callback = None
        self.eta_callback = None
        self.expected_md5 = ""
        self.timeout = 30
        self.max_retries = 3
        self.retry_count = 0

    def set_download_url(self, url: str):
        self.download_url = url

    def set_save_path(self, path: str):
        self.save_path = path
        self.temp_file = path + ".tmp"

    def set_file_size(self, size: int):
        self.file_size = size

    def set_expected_md5(self, md5: str):
        self.expected_md5 = md5

    def set_timeout(self, timeout: int):
        self.timeout = timeout

    def set_max_retries(self, retries: int):
        self.max_retries = retries

    def set_chunk_size(self, size: int):
        self.chunk_size = size

    def set_progress_callback(self, callback: Callable[[float], None]):
        self.progress_callback = callback

    def set_speed_callback(self, callback: Callable[[str], None]):
        self.speed_callback = callback

    def set_eta_callback(self, callback: Callable[[str], None]):
        self.eta_callback = callback

    def start_download(self):
        if self.is_downloading:
            return False
        
        if not self.download_url or not self.save_path:
            self.downloadFailed.emit("下载URL或保存路径未设置")
            return False
        
        self.is_downloading = True
        self.is_paused = False
        self.downloaded_size = 0
        self.retry_count = 0
        
        import threading
        self.cancel_event = threading.Event()
        
        self.downloadStarted.emit(self.download_url)
        
        return self._download()

    def _download(self) -> bool:
        try:
            response = requests.get(self.download_url, stream=True, timeout=self.timeout)
            
            if response.status_code == 200:
                total_size = int(response.headers.get('content-length', self.file_size))
                self.file_size = total_size if total_size > 0 else self.file_size
                
                start_time = time.time()
                last_update_time = start_time
                
                mode = 'ab' if self.downloaded_size > 0 else 'wb'
                with open(self.temp_file, mode) as f:
                    for chunk in response.iter_content(chunk_size=self.chunk_size):
                        if self.cancel_event and self.cancel_event.is_set():
                            self.is_downloading = False
                            self.downloadCancelled.emit()
                            return False
                        
                        while self.is_paused:
                            if self.cancel_event and self.cancel_event.is_set():
                                self.is_downloading = False
                                self.downloadCancelled.emit()
                                return False
                            time.sleep(0.1)
                        
                        if chunk:
                            f.write(chunk)
                            self.downloaded_size += len(chunk)
                            
                            current_time = time.time()
                            if current_time - last_update_time > 0.5:
                                progress = (self.downloaded_size / self.file_size * 100) if self.file_size > 0 else 0
                                elapsed = current_time - start_time
                                speed = (self.downloaded_size / elapsed) if elapsed > 0 else 0
                                speed_str = self._format_speed(speed)
                                eta_str = self._calculate_eta(self.downloaded_size, self.file_size, speed)
                                
                                self.downloadProgress.emit(progress, speed_str, eta_str)
                                
                                if self.progress_callback:
                                    self.progress_callback(progress)
                                if self.speed_callback:
                                    self.speed_callback(speed_str)
                                if self.eta_callback:
                                    self.eta_callback(eta_str)
                                
                                last_update_time = current_time
                
                if self._verify_file():
                    os.rename(self.temp_file, self.save_path)
                    self.is_downloading = False
                    self.downloadComplete.emit(self.save_path)
                    return True
                else:
                    self._cleanup()
                    self.downloadFailed.emit("文件验证失败")
                    return False
            else:
                self._cleanup()
                self.downloadFailed.emit(f"下载失败，状态码: {response.status_code}")
                return False
                
        except requests.exceptions.Timeout:
            if self.retry_count < self.max_retries:
                self.retry_count += 1
                time.sleep(2)
                return self._download()
            else:
                self._cleanup()
                self.downloadFailed.emit("下载超时")
                return False
        except Exception as e:
            if self.retry_count < self.max_retries:
                self.retry_count += 1
                time.sleep(2)
                return self._download()
            else:
                self._cleanup()
                self.downloadFailed.emit(f"下载失败: {str(e)}")
                return False

    def pause_download(self):
        if self.is_downloading and not self.is_paused:
            self.is_paused = True
            self.downloadPaused.emit()

    def resume_download(self):
        if self.is_downloading and self.is_paused:
            self.is_paused = False
            self.downloadResumed.emit()

    def cancel_download(self):
        if self.cancel_event:
            self.cancel_event.set()

    def _verify_file(self) -> bool:
        if not os.path.exists(self.temp_file):
            return False
        
        if not self.expected_md5:
            return True
        
        try:
            md5_hash = hashlib.md5()
            with open(self.temp_file, 'rb') as f:
                for chunk in iter(lambda: f.read(8192), b''):
                    md5_hash.update(chunk)
            return md5_hash.hexdigest() == self.expected_md5
        except:
            return False

    def _format_speed(self, speed: float) -> str:
        if speed > 1024 * 1024 * 1024:
            return f"{speed / (1024 * 1024 * 1024):.2f} GB/s"
        elif speed > 1024 * 1024:
            return f"{speed / (1024 * 1024):.2f} MB/s"
        elif speed > 1024:
            return f"{speed / 1024:.2f} KB/s"
        return f"{speed:.2f} B/s"

    def _calculate_eta(self, downloaded: int, total: int, speed: float) -> str:
        if speed == 0 or total == 0:
            return "计算中..."
        remaining = total - downloaded
        seconds = remaining / speed
        if seconds < 60:
            return f"{int(seconds)}秒"
        elif seconds < 3600:
            return f"{int(seconds / 60)}分{int(seconds % 60)}秒"
        return f"{int(seconds / 3600)}小时{int((seconds % 3600) / 60)}分"

    def _cleanup(self):
        self.is_downloading = False
        if os.path.exists(self.temp_file):
            os.remove(self.temp_file)

    def get_download_progress(self) -> float:
        if self.file_size > 0:
            return (self.downloaded_size / self.file_size) * 100
        return 0.0

    def get_downloaded_size(self) -> int:
        return self.downloaded_size

    def get_file_size(self) -> int:
        return self.file_size

    def is_active(self) -> bool:
        return self.is_downloading

    def is_paused_state(self) -> bool:
        return self.is_paused

    def get_temp_file_path(self) -> str:
        return self.temp_file

    def can_resume(self) -> bool:
        return os.path.exists(self.temp_file) and self.downloaded_size > 0

    def reset(self):
        self._cleanup()
        self.download_url = ""
        self.save_path = ""
        self.file_size = 0
        self.downloaded_size = 0
        self.is_downloading = False
        self.is_paused = False
        self.cancel_event = None
        self.retry_count = 0

    def get_file_info(self, url: str) -> dict:
        try:
            response = requests.head(url, timeout=10)
            if response.status_code == 200:
                return {
                    'size': int(response.headers.get('content-length', 0)),
                    'content_type': response.headers.get('content-type', ''),
                    'supports_range': 'accept-ranges' in response.headers
                }
        except:
            pass
        return {
            'size': 0,
            'content_type': '',
            'supports_range': False
        }

    def download_with_resume(self, url: str, save_path: str, expected_md5: str = "") -> bool:
        self.set_download_url(url)
        self.set_save_path(save_path)
        self.set_expected_md5(expected_md5)
        
        if self.can_resume():
            file_info = self.get_file_info(url)
            if file_info['supports_range']:
                self.downloaded_size = os.path.getsize(self.temp_file)
        
        return self.start_download()
