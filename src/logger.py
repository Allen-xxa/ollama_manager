import os
import sys
import logging
import time
from datetime import datetime

class Logger:
    def __init__(self, name='OllamaManager', level=logging.INFO):
        self.name = name
        self.level = level
        
        # 获取项目根目录
        if getattr(sys, 'frozen', False):
            self.project_root = os.path.dirname(sys.executable)
        else:
            self.project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        
        # 创建logs目录
        self.log_dir = os.path.join(self.project_root, 'logs')
        os.makedirs(self.log_dir, exist_ok=True)
        
        # 设置日志格式
        self.formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        # 初始化日志记录器
        self.logger = logging.getLogger(name)
        self.logger.setLevel(level)
        self.logger.handlers = []  # 清空已有处理器
        
        # 控制台处理器
        self.console_handler = logging.StreamHandler()
        self.console_handler.setFormatter(self.formatter)
        self.logger.addHandler(self.console_handler)
        
        # 文件处理器
        self.log_file = os.path.join(self.log_dir, f'{datetime.now().strftime("%Y-%m-%d_%H-%M-%S")}.log')
        self.file_handler = logging.FileHandler(self.log_file, encoding='utf-8')
        self.file_handler.setFormatter(self.formatter)
        self.logger.addHandler(self.file_handler)
    
    def debug(self, message):
        self.logger.debug(message)
    
    def info(self, message):
        self.logger.info(message)
    
    def warning(self, message):
        self.logger.warning(message)
    
    def error(self, message):
        self.logger.error(message)
    
    def critical(self, message):
        self.logger.critical(message)
    
    def get_log_file_path(self):
        """获取当前日志文件路径"""
        return self.log_file

# 创建全局日志实例
logger = Logger()
