import os
import sys
import json
import time
import shutil
import zipfile
import argparse
import subprocess
from pathlib import Path
from PyQt6.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QWidget, QLabel, QProgressBar, QTextEdit, QPushButton
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QTimer
from PyQt6.QtGui import QFont
import update_helper
from logger import logger


class UpdateWorker(QThread):
    progress_updated = pyqtSignal(int, str)
    log_updated = pyqtSignal(str)
    update_finished = pyqtSignal(bool, str)

    def __init__(self, update_info):
        super().__init__()
        self.update_info = update_info
        self.cancelled = False

    def run(self):
        try:
            self.log_updated.emit("=" * 50)
            logger.info("=" * 50)
            self.log_updated.emit("开始更新流程")
            logger.info("开始更新流程")
            self.log_updated.emit("=" * 50)
            logger.info("=" * 50)

            self.progress_updated.emit(5, "检查更新信息...")
            self.log_updated.emit(f"更新包路径: {self.update_info.get('update_file', '')}")
            logger.info(f"更新包路径: {self.update_info.get('update_file', '')}")
            self.log_updated.emit(f"目标目录: {self.update_info.get('target_dir', '')}")
            logger.info(f"目标目录: {self.update_info.get('target_dir', '')}")
            self.log_updated.emit(f"主程序路径: {self.update_info.get('main_exe', '')}")
            logger.info(f"主程序路径: {self.update_info.get('main_exe', '')}")

            if not os.path.exists(self.update_info['update_file']):
                raise Exception(f"更新包不存在: {self.update_info['update_file']}")

            if not os.path.exists(self.update_info['target_dir']):
                raise Exception(f"目标目录不存在: {self.update_info['target_dir']}")

            self.progress_updated.emit(10, "检查主程序进程...")
            self.log_updated.emit("检查主程序进程...")
            logger.info("检查主程序进程...")
            main_exe = self.update_info['main_exe']
            process_name = os.path.basename(main_exe)

            if update_helper.is_process_running(process_name):
                self.log_updated.emit(f"检测到主程序正在运行: {process_name}")
                logger.info(f"检测到主程序正在运行: {process_name}")
                self.progress_updated.emit(15, "等待主程序退出...")
                self.log_updated.emit("等待主程序退出...")
                logger.info("等待主程序退出...")
                
                wait_result = update_helper.wait_for_process_exit(process_name, timeout=30)
                if not wait_result:
                    self.log_updated.emit("主程序未在30秒内退出，尝试强制终止...")
                    logger.warning("主程序未在30秒内退出，尝试强制终止...")
                    if update_helper.kill_process(process_name):
                        self.log_updated.emit("主程序已强制终止")
                        logger.info("主程序已强制终止")
                    else:
                        raise Exception("无法终止主程序进程")
                
                time.sleep(2)
            else:
                self.log_updated.emit("主程序未运行")
                logger.info("主程序未运行")

            self.progress_updated.emit(20, "创建备份...")
            self.log_updated.emit("创建备份...")
            logger.info("创建备份...")
            backup_dir = self.update_info.get('backup_dir', '')
            if backup_dir:
                os.makedirs(backup_dir, exist_ok=True)
                backup_result = update_helper.create_backup(
                self.update_info['target_dir'],
                backup_dir,
                lambda msg: self.log_updated.emit(msg)
            )
                if backup_result:
                    self.log_updated.emit(f"备份创建成功: {backup_dir}")
                    logger.info(f"备份创建成功: {backup_dir}")
                else:
                    self.log_updated.emit("警告: 备份创建失败，继续更新...")
                    logger.warning("备份创建失败，继续更新...")

            self.progress_updated.emit(30, "解压更新包...")
            self.log_updated.emit("解压更新包...")
            logger.info("解压更新包...")
            temp_dir = os.path.join(self.update_info['target_dir'], 'temp', 'update_temp')
            os.makedirs(temp_dir, exist_ok=True)
            
            # 清理临时目录（如果存在）
            if os.path.exists(temp_dir):
                shutil.rmtree(temp_dir)
                os.makedirs(temp_dir, exist_ok=True)
            
            extract_result = update_helper.extract_zip(self.update_info['update_file'], temp_dir, lambda msg: self.log_updated.emit(msg))
            if not extract_result:
                # 解压失败，终止更新流程
                raise Exception("更新包解压失败")
            
            self.log_updated.emit("更新包解压完成")
            logger.info("更新包解压完成")

            self.progress_updated.emit(50, "验证文件完整性...")
            self.log_updated.emit("验证文件完整性...")
            logger.info("验证文件完整性...")
            expected_md5 = self.update_info.get('md5', '')
            if expected_md5:
                update_file_md5 = update_helper.calculate_md5(self.update_info['update_file'])
                if update_file_md5 != expected_md5:
                    raise Exception(f"MD5校验失败: 期望 {expected_md5}, 实际 {update_file_md5}")
                self.log_updated.emit("MD5校验通过")
                logger.info("MD5校验通过")
            else:
                self.log_updated.emit("跳过MD5校验（未提供MD5值）")
                logger.info("跳过MD5校验（未提供MD5值）")

            self.progress_updated.emit(60, "复制文件...")
            self.log_updated.emit("复制文件...")
            logger.info("复制文件...")
            update_helper.copy_files(temp_dir, self.update_info['target_dir'], lambda msg: self.log_updated.emit(msg))
            self.log_updated.emit("文件复制完成")
            logger.info("文件复制完成")

            self.progress_updated.emit(80, "清理临时文件...")
            self.log_updated.emit("清理临时文件...")
            logger.info("清理临时文件...")
            try:
                shutil.rmtree(temp_dir)
                self.log_updated.emit("临时文件清理完成")
                logger.info("临时文件清理完成")
            except Exception as e:
                self.log_updated.emit(f"警告: 清理临时文件失败: {str(e)}")
                logger.warning(f"清理临时文件失败: {str(e)}")

            self.progress_updated.emit(90, "启动新版本...")
            self.log_updated.emit("启动新版本...")
            logger.info("启动新版本...")
            
            # 判断当前启动方式，根据不同模式采用不同的启动方式
            if main_exe.endswith('.py'):
                # 源码模式：使用根目录的.venv虚拟环境启动
                logger.info(f"检测到源码模式，主程序路径: {main_exe}")
                
                # 构建虚拟环境Python路径
                project_root = os.path.dirname(os.path.dirname(main_exe))
                venv_python = os.path.join(project_root, ".venv", "Scripts", "python.exe")
                
                if os.path.exists(venv_python):
                    # 使用虚拟环境Python启动
                    logger.info(f"使用虚拟环境启动: {venv_python}")
                    subprocess.Popen([venv_python, main_exe], shell=True)
                    self.log_updated.emit("新版本已启动")
                    logger.info("新版本已启动")
                else:
                    # 虚拟环境不存在，使用系统Python启动
                    logger.warning(f"虚拟环境不存在: {venv_python}")
                    logger.info(f"使用系统Python启动: {sys.executable}")
                    subprocess.Popen([sys.executable, main_exe], shell=True)
                    self.log_updated.emit("新版本已启动")
                    logger.info("新版本已启动")
            else:
                # 编译模式：使用.exe启动
                logger.info(f"检测到编译模式，主程序路径: {main_exe}")
                main_exe_path = main_exe
                if os.path.exists(main_exe_path):
                    subprocess.Popen([main_exe_path], shell=True)
                    self.log_updated.emit("新版本已启动")
                    logger.info("新版本已启动")
                else:
                    self.log_updated.emit(f"警告: 主程序不存在: {main_exe_path}")
                    logger.warning(f"主程序不存在: {main_exe_path}")

            self.progress_updated.emit(100, "更新完成！")
            self.log_updated.emit("=" * 50)
            self.log_updated.emit("更新成功完成！")
            self.log_updated.emit("=" * 50)
            logger.info("=" * 50)
            logger.info("更新成功完成！")
            logger.info("=" * 50)
            
            self.update_finished.emit(True, "更新成功！")
            
        except Exception as e:
            error_msg = f"错误: {str(e)}"
            self.log_updated.emit(error_msg)
            logger.error(error_msg)
            self.log_updated.emit("=" * 50)
            self.log_updated.emit("更新失败！")
            self.log_updated.emit("=" * 50)
            logger.error("=" * 50)
            logger.error("更新失败！")
            logger.error("=" * 50)
            
            self.update_finished.emit(False, str(e))


class UpdateWindow(QMainWindow):
    def __init__(self, update_info):
        super().__init__()
        self.update_info = update_info
        self.worker = None
        self.init_ui()
        self.start_update()

    def init_ui(self):
        self.setWindowTitle("Ollama Manager - 更新程序")
        self.setMinimumSize(600, 500)
        self.setStyleSheet("""
            QMainWindow {
                background-color: #121212;
            }
            QLabel {
                color: #ffffff;
                font-family: "Microsoft YaHei", sans-serif;
            }
            QProgressBar {
                border: 2px solid #333333;
                border-radius: 5px;
                text-align: center;
                background-color: #1e1e1e;
                color: #ffffff;
            }
            QProgressBar::chunk {
                background-color: #3b82f6;
                border-radius: 3px;
            }
            QTextEdit {
                background-color: #1e1e1e;
                color: #00ff00;
                border: 1px solid #333333;
                border-radius: 5px;
                font-family: "Consolas", monospace;
                font-size: 10pt;
            }
            QPushButton {
                background-color: #3b82f6;
                color: #ffffff;
                border: none;
                border-radius: 5px;
                padding: 8px 16px;
                font-size: 12pt;
            }
            QPushButton:hover {
                background-color: #2563eb;
            }
            QPushButton:disabled {
                background-color: #333333;
                color: #666666;
            }
        """)

        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)
        layout.setSpacing(20)
        layout.setContentsMargins(30, 30, 30, 30)

        title_label = QLabel("Ollama Manager 更新程序")
        title_label.setFont(QFont("Microsoft YaHei", 16, QFont.Weight.Bold))
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label)

        version_label = QLabel(f"更新版本: {self.update_info.get('version', '未知')}")
        version_label.setFont(QFont("Microsoft YaHei", 10))
        version_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(version_label)

        self.status_label = QLabel("准备更新...")
        self.status_label.setFont(QFont("Microsoft YaHei", 10))
        self.status_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(self.status_label)

        self.progress_bar = QProgressBar()
        self.progress_bar.setMinimum(0)
        self.progress_bar.setMaximum(100)
        self.progress_bar.setValue(0)
        layout.addWidget(self.progress_bar)

        self.log_text = QTextEdit()
        self.log_text.setReadOnly(True)
        layout.addWidget(self.log_text)

        self.close_button = QPushButton("关闭")
        self.close_button.setEnabled(False)
        self.close_button.clicked.connect(self.close)
        layout.addWidget(self.close_button)

    def start_update(self):
        self.worker = UpdateWorker(self.update_info)
        self.worker.progress_updated.connect(self.on_progress_updated)
        self.worker.log_updated.connect(self.on_log_updated)
        self.worker.update_finished.connect(self.on_update_finished)
        self.worker.start()

    def on_progress_updated(self, value, status):
        self.progress_bar.setValue(value)
        self.status_label.setText(status)

    def on_log_updated(self, message):
        self.log_text.append(message)

    def on_update_finished(self, success, message):
        if success:
            self.status_label.setText("更新完成！")
            self.close_button.setText("关闭")
            self.close_button.setEnabled(True)
            # 更新成功后，延迟2秒自动退出更新程序
            self.log_text.append("更新完成，2秒后自动退出更新程序...")
            QTimer.singleShot(2000, self.close)
        else:
            self.status_label.setText(f"更新失败：{message}")
            self.close_button.setText("关闭")
            self.close_button.setEnabled(True)


def main():
    app = QApplication(sys.argv)
    
    parser = argparse.ArgumentParser(description="Ollama Manager 更新程序")
    parser.add_argument("--update-info", required=True, help="更新信息JSON文件路径")
    args = parser.parse_args()

    try:
        with open(args.update_info, 'r', encoding='utf-8') as f:
            update_info = json.load(f)
    except Exception as e:
        print(f"读取更新信息失败: {str(e)}")
        sys.exit(1)

    window = UpdateWindow(update_info)
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
