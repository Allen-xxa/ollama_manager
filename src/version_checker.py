import re
from typing import Tuple, Optional
from PyQt6.QtCore import QObject, pyqtSignal


class VersionChecker(QObject):
    versionChecked = pyqtSignal(dict)
    versionCompareResult = pyqtSignal(int)
    versionCheckFailed = pyqtSignal(str)

    def __init__(self, parent=None):
        super().__init__(parent)

    def parse_version(self, version_str: str) -> Tuple[int, int, int, Optional[str]]:
        match = re.match(r'(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9]+))?', version_str)
        if match:
            major = int(match.group(1))
            minor = int(match.group(2))
            patch = int(match.group(3))
            prerelease = match.group(4)
            return (major, minor, patch, prerelease)
        return (0, 0, 0, None)

    def compare_versions(self, v1: str, v2: str) -> int:
        v1_parsed = self.parse_version(v1)
        v2_parsed = self.parse_version(v2)
        
        for i in range(3):
            if v1_parsed[i] > v2_parsed[i]:
                return 1
            elif v1_parsed[i] < v2_parsed[i]:
                return -1
        
        v1_pre = v1_parsed[3]
        v2_pre = v2_parsed[3]
        
        if v1_pre is None and v2_pre is not None:
            return 1
        elif v1_pre is not None and v2_pre is None:
            return -1
        elif v1_pre is not None and v2_pre is not None:
            if v1_pre > v2_pre:
                return 1
            elif v1_pre < v2_pre:
                return -1
        
        return 0

    def is_version_newer(self, current: str, remote: str) -> bool:
        return self.compare_versions(remote, current) > 0

    def is_version_older(self, current: str, remote: str) -> bool:
        return self.compare_versions(remote, current) < 0

    def is_version_equal(self, v1: str, v2: str) -> bool:
        return self.compare_versions(v1, v2) == 0

    def get_version_info(self, version: str) -> dict:
        parsed = self.parse_version(version)
        return {
            'version': version,
            'major': parsed[0],
            'minor': parsed[1],
            'patch': parsed[2],
            'prerelease': parsed[3],
            'is_stable': parsed[3] is None
        }

    def format_version(self, major: int, minor: int, patch: int, prerelease: Optional[str] = None) -> str:
        version = f"{major}.{minor}.{patch}"
        if prerelease:
            version += f"-{prerelease}"
        return version

    def validate_version(self, version: str) -> bool:
        return bool(re.match(r'^\d+\.\d+\.\d+(?:-[a-zA-Z0-9]+)?$', version))

    def get_version_distance(self, v1: str, v2: str) -> str:
        v1_parsed = self.parse_version(v1)
        v2_parsed = self.parse_version(v2)
        
        major_diff = abs(v2_parsed[0] - v1_parsed[0])
        minor_diff = abs(v2_parsed[1] - v1_parsed[1])
        patch_diff = abs(v2_parsed[2] - v1_parsed[2])
        
        if major_diff > 0:
            return f"主版本更新 (+{major_diff}.{minor_diff}.{patch_diff})"
        elif minor_diff > 0:
            return f"次版本更新 (+0.{minor_diff}.{patch_diff})"
        elif patch_diff > 0:
            return f"补丁更新 (+0.0.{patch_diff})"
        else:
            return "版本相同"

    def get_update_type(self, current: str, remote: str) -> str:
        comparison = self.compare_versions(remote, current)
        
        if comparison == 0:
            return "无需更新"
        elif comparison < 0:
            return "版本回退"
        
        current_parsed = self.parse_version(current)
        remote_parsed = self.parse_version(remote)
        
        if remote_parsed[0] > current_parsed[0]:
            return "主版本更新"
        elif remote_parsed[1] > current_parsed[1]:
            return "次版本更新"
        elif remote_parsed[2] > current_parsed[2]:
            return "补丁更新"
        else:
            return "预发布版本更新"

    def should_update(self, current: str, remote: str, force: bool = False) -> bool:
        if force:
            return True
        
        return self.is_version_newer(current, remote)

    def get_compatible_versions(self, version: str, max_major_diff: int = 1) -> list:
        parsed = self.parse_version(version)
        compatible = []
        
        for major_diff in range(max_major_diff + 1):
            for minor in range(10):
                for patch in range(10):
                    new_major = parsed[0] + major_diff
                    compatible.append(f"{new_major}.{minor}.{patch}")
        
        return compatible

    def get_next_version(self, version: str, increment_type: str = "patch") -> str:
        parsed = self.parse_version(version)
        
        if increment_type == "major":
            return self.format_version(parsed[0] + 1, 0, 0)
        elif increment_type == "minor":
            return self.format_version(parsed[0], parsed[1] + 1, 0)
        elif increment_type == "patch":
            return self.format_version(parsed[0], parsed[1], parsed[2] + 1)
        else:
            return version

    def get_version_history(self, versions: list) -> list:
        sorted_versions = sorted(versions, key=lambda v: self.parse_version(v), reverse=True)
        history = []
        
        for i, version in enumerate(sorted_versions):
            if i > 0:
                prev_version = sorted_versions[i - 1]
                distance = self.get_version_distance(version, prev_version)
                update_type = self.get_update_type(version, prev_version)
            else:
                distance = "最新版本"
                update_type = "当前版本"
            
            history.append({
                'version': version,
                'distance': distance,
                'update_type': update_type
            })
        
        return history

    def check_version_requirements(self, version: str, min_version: str = None, 
                                    max_version: str = None) -> bool:
        if min_version and self.compare_versions(version, min_version) < 0:
            return False
        
        if max_version and self.compare_versions(version, max_version) > 0:
            return False
        
        return True

    def get_version_description(self, version: str) -> str:
        info = self.get_version_info(version)
        
        description = f"版本 {version}"
        
        if info['prerelease']:
            description += f" (预发布: {info['prerelease']})"
        else:
            description += " (稳定版)"
        
        return description

    def is_prerelease(self, version: str) -> bool:
        parsed = self.parse_version(version)
        return parsed[3] is not None

    def get_stable_version(self, version: str) -> str:
        parsed = self.parse_version(version)
        return self.format_version(parsed[0], parsed[1], parsed[2])
