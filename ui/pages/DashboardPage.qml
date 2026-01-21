import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: dashboardPage
    property string currentPage: "dashboard"
    width: parent.width
    height: parent.height
    color: "#121212"
    
    // 背景图片
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "../assets/img/bg.jpg"
        fillMode: Image.PreserveAspectCrop
        anchors.centerIn: parent
        opacity: 0.3 // 调整透明度以确保内容清晰可见
    }
    
    // 获取当前日期和时间
    property var currentDate: new Date()
    
    // 格式化日期
    property string formattedDate: {
        var year = currentDate.getFullYear();
        var month = currentDate.getMonth() + 1;
        var day = currentDate.getDate();
        var weekday = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"][currentDate.getDay()];
        return year + "年" + month + "月" + day + "日 " + weekday;
    }
    
    // 格式化问候语
    property string greeting: {
        var hour = currentDate.getHours();
        if (hour >= 12 && hour < 18) {
            return "下午好";
        } else if (hour >= 18) {
            return "晚上好";
        }
        return "早上好";
    }
    
    // 仪表盘数据
    property int activeModels: 0
    property int totalModels: 0
    property string diskUsage: "0.0 GB"
    property string vramUsage: "0 B"
    property var activeModelsDetails: []
    
    // 监听ModelManager的信号
    Connections {
        target: modelManager
        
        // 监听模型列表更新，获取已安装模型总数
        function onModelsUpdated(models) {
            totalModels = models.length;
        }
        
        // 监听活跃模型数量更新
        function onActiveModelsUpdated(count) {
            activeModels = count;
        }
        
        // 监听磁盘使用情况更新
        function onDiskUsageUpdated(usage) {
            diskUsage = usage;
        }
        
        // 监听显存使用情况更新
        function onVramUsageUpdated(usage) {
            vramUsage = usage;
        }
        
        // 监听活跃模型详细信息更新
        function onActiveModelsDetailsUpdated(models) {
            activeModelsDetails = models;
        }
    }
    
    // 定时器，定期更新数据
    Timer {
        interval: 5000 // 5秒更新一次
        running: true
        repeat: true
        triggeredOnStart: true
        
        onTriggered: {
            // 更新当前时间
            currentDate = new Date();
            // 请求更新模型数据
            modelManager.getModels();
        }
    }
    
    // 顶部日期
    Label {
        x: 20
        y: 20
        width: parent.width - 40
        height: 20
        text: formattedDate
        font.pointSize: 12
        color: "#ffffff"
    }
    
    // 顶部问候语
    Label {
        x: 20
        y: 50
        width: parent.width - 40
        height: 30
        text: greeting
        font.pointSize: 24
        font.bold: true
        color: "#ffffff"
    }

    // 卡片容器
    Rectangle {
        x: 20
        y: 130
        width: parent.width - 40
        height: 200
        color: "transparent"
        
        // 活跃模型卡片
            Rectangle {
                id: activeModelsCard
                x: 0
                y: 0
                width: (parent.width - 60) / 4
                height: 200
                color: "#1e1e1e"
                radius: 12
                border {
                    width: 1
                    color: "#333333"
                }
                
                // 垂直居中容器
                Column {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    spacing: 15
                    
                    // 图标
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#2563eb"
                        radius: 8
                        
                        // 活跃模型图标 - 脉冲波形（居中）
                        Canvas {
                            anchors.fill: parent
                            anchors.margins: 8
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = "white";
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                ctx.moveTo(0, height / 2 + height * 0.1); // 基线向下移动
                                // 创建多个脉冲波峰，进一步向下移动
                                for (var i = 0; i < 3; i++) {
                                    var x = width * (i * 0.4 + 0.2);
                                    var amplitude = height * 0.3; // 减小振幅，使波形顶部更低
                                    var baseline = height / 2 + height * 0.1; // 基线向下移动
                                    ctx.quadraticCurveTo(x - width * 0.1, baseline - amplitude / 2, x, baseline - amplitude);
                                    ctx.quadraticCurveTo(x + width * 0.1, baseline - amplitude / 2, x + width * 0.2, baseline);
                                }
                                ctx.stroke();
                            }
                        }
                    }
                    
                    // 数值和标签
                    Row {
                        spacing: 8
                        
                        // 数值
                        Label {
                            text: activeModels
                            font.pointSize: 32
                            font.bold: true
                            color: "#ffffff"
                        }
                        
                        // 标签
                        Label {
                            text: "活跃"
                            font.pointSize: 12
                            color: "#9ca3af"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // 描述
                    Label {
                        text: "运行中的模型"
                        font.pointSize: 12
                        color: "#9ca3af"
                    }
                }
            }
            
            // 显存使用卡片
            Rectangle {
                id: vramUsageCard
                x: (parent.width - 60) / 4 + 20
                y: 0
                width: (parent.width - 60) / 4
                height: 200
                color: "#1e1e1e"
                radius: 12
                border {
                    width: 1
                    color: "#333333"
                }
                
                // 垂直居中容器
                Column {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    spacing: 15
                    
                    // 图标
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#8b5cf6"
                        radius: 8
                        
                        // 显存使用图标 - GPU芯片
                        Canvas {
                            anchors.fill: parent
                            anchors.margins: 8
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = "white";
                                ctx.lineWidth = 2;
                                
                                // GPU芯片外框
                                ctx.strokeRect(width * 0.1, height * 0.1, width * 0.8, height * 0.8);
                                
                                // 芯片内部结构
                                // 中心处理单元
                                ctx.strokeRect(width * 0.3, height * 0.3, width * 0.4, height * 0.4);
                                
                                // 显存模块 - 四个角落
                                ctx.strokeRect(width * 0.15, width * 0.15, width * 0.15, width * 0.15);
                                ctx.strokeRect(width * 0.7, width * 0.15, width * 0.15, width * 0.15);
                                ctx.strokeRect(width * 0.15, width * 0.7, width * 0.15, width * 0.15);
                                ctx.strokeRect(width * 0.7, width * 0.7, width * 0.15, width * 0.15);
                                
                                // 连接线
                                ctx.beginPath();
                                ctx.moveTo(width * 0.5, height * 0.3);
                                ctx.lineTo(width * 0.5, height * 0.2);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.5, height * 0.7);
                                ctx.lineTo(width * 0.5, height * 0.8);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.3, height * 0.5);
                                ctx.lineTo(width * 0.2, height * 0.5);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.7, height * 0.5);
                                ctx.lineTo(width * 0.8, height * 0.5);
                                ctx.stroke();
                            }
                        }
                    }
                    
                    // 数值
                    Label {
                        text: vramUsage
                        font.pointSize: 32
                        font.bold: true
                        color: "#ffffff"
                    }
                    
                    // 描述
                    Label {
                        text: "显存使用"
                        font.pointSize: 12
                        color: "#9ca3af"
                    }
                }
            }
            
            // 已安装模型卡片
            Rectangle {
                id: totalModelsCard
                x: ((parent.width - 60) / 4 + 20) * 2
                y: 0
                width: (parent.width - 60) / 4
                height: 200
                color: "#1e1e1e"
                radius: 12
                border {
                    width: 1
                    color: "#333333"
                }
                
                // 垂直居中容器
                Column {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    spacing: 15
                    
                    // 图标
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#10b981"
                        radius: 8
                        
                        // 已安装模型图标 - 神经网络
                        Canvas {
                            anchors.fill: parent
                            anchors.margins: 8
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = "white";
                                ctx.lineWidth = 2;
                                
                                // 神经网络节点
                                var nodeRadius = width * 0.1;
                                
                                // 第一层节点
                                ctx.beginPath();
                                ctx.arc(width * 0.2, height * 0.3, nodeRadius, 0, Math.PI * 2);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.arc(width * 0.2, height * 0.7, nodeRadius, 0, Math.PI * 2);
                                ctx.stroke();
                                
                                // 第二层节点
                                ctx.beginPath();
                                ctx.arc(width * 0.5, height * 0.2, nodeRadius, 0, Math.PI * 2);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.arc(width * 0.5, height * 0.5, nodeRadius, 0, Math.PI * 2);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.arc(width * 0.5, height * 0.8, nodeRadius, 0, Math.PI * 2);
                                ctx.stroke();
                                
                                // 第三层节点
                                ctx.beginPath();
                                ctx.arc(width * 0.8, height * 0.3, nodeRadius, 0, Math.PI * 2);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.arc(width * 0.8, height * 0.7, nodeRadius, 0, Math.PI * 2);
                                ctx.stroke();
                                
                                // 连接线
                                // 第一层到第二层
                                ctx.beginPath();
                                ctx.moveTo(width * 0.2, height * 0.3);
                                ctx.lineTo(width * 0.5, height * 0.2);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.2, height * 0.3);
                                ctx.lineTo(width * 0.5, height * 0.5);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.2, height * 0.3);
                                ctx.lineTo(width * 0.5, height * 0.8);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.2, height * 0.7);
                                ctx.lineTo(width * 0.5, height * 0.2);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.2, height * 0.7);
                                ctx.lineTo(width * 0.5, height * 0.5);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.2, height * 0.7);
                                ctx.lineTo(width * 0.5, height * 0.8);
                                ctx.stroke();
                                
                                // 第二层到第三层
                                ctx.beginPath();
                                ctx.moveTo(width * 0.5, height * 0.2);
                                ctx.lineTo(width * 0.8, height * 0.3);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.5, height * 0.2);
                                ctx.lineTo(width * 0.8, height * 0.7);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.5, height * 0.5);
                                ctx.lineTo(width * 0.8, height * 0.3);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.5, height * 0.5);
                                ctx.lineTo(width * 0.8, height * 0.7);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.5, height * 0.8);
                                ctx.lineTo(width * 0.8, height * 0.3);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                ctx.moveTo(width * 0.5, height * 0.8);
                                ctx.lineTo(width * 0.8, height * 0.7);
                                ctx.stroke();
                            }
                        }
                    }
                    
                    // 数值和标签
                    Row {
                        spacing: 8
                        
                        // 数值
                        Label {
                            text: totalModels
                            font.pointSize: 32
                            font.bold: true
                            color: "#ffffff"
                        }
                        
                        // 标签
                        Label {
                            text: "模型"
                            font.pointSize: 12
                            color: "#9ca3af"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // 描述
                    Label {
                        text: "已安装总数"
                        font.pointSize: 12
                        color: "#9ca3af"
                    }
                }
            }
            
            // 磁盘使用卡片
            Rectangle {
                id: diskUsageCard
                x: ((parent.width - 60) / 4 + 20) * 3
                y: 0
                width: (parent.width - 60) / 4
                height: 200
                color: "#1e1e1e"
                radius: 12
                border {
                    width: 1
                    color: "#333333"
                }
                
                // 垂直居中容器
                Column {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    spacing: 15
                    
                    // 图标
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#f59e0b"
                        radius: 8
                        
                        // 磁盘使用图标 - 现代硬盘
                        Canvas {
                            anchors.fill: parent
                            anchors.margins: 8
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = "white";
                                ctx.lineWidth = 2;
                                
                                // 硬盘外框
                                ctx.strokeRect(width * 0.1, height * 0.2, width * 0.8, height * 0.6);
                                
                                // 硬盘内部结构
                                // 数据存储区域
                                ctx.strokeRect(width * 0.2, height * 0.3, width * 0.6, height * 0.4);
                                
                                // 硬盘读写头
                                ctx.beginPath();
                                ctx.moveTo(width * 0.5, height * 0.2);
                                ctx.lineTo(width * 0.5, height * 0.3);
                                ctx.stroke();
                                
                                // 硬盘数据轨道
                                for (var i = 1; i <= 3; i++) {
                                    var y = height * 0.3 + (height * 0.4 * i) / 4;
                                    ctx.beginPath();
                                    ctx.moveTo(width * 0.2, y);
                                    ctx.lineTo(width * 0.8, y);
                                    ctx.stroke();
                                }
                                
                                // 硬盘接口
                                ctx.strokeRect(width * 0.4, height * 0.8, width * 0.2, height * 0.1);
                            }
                        }
                    }
                    
                    // 数值
                    Label {
                        text: diskUsage
                        font.pointSize: 32
                        font.bold: true
                        color: "#ffffff"
                    }
                    
                    // 描述
                    Label {
                        text: "磁盘使用"
                        font.pointSize: 12
                        color: "#9ca3af"
                    }
                }
        }
    }
    
    // 运行中模型显示区域
    Rectangle {
        x: 20
        y: 350
        width: parent.width - 40
        height: 400
        color: "transparent"
        
        // 标题
        Label {
            x: 0
            y: 0
            width: parent.width
            height: 30
            text: "运行中的模型"
            font.pointSize: 16
            font.bold: true
            color: "#ffffff"
        }
        
        // 空状态显示
        Rectangle {
            id: emptyState
            x: 0
            y: 40
            width: parent.width
            height: 100
            color: "#1e1e1e"
            radius: 12
            border {
                width: 1
                color: "#333333"
            }
            visible: activeModelsDetails.length == 0
            
            Column {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 10
                
                // 图标和文字组合
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    
                    // 图标
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#374151"
                        radius: 20
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Canvas {
                            anchors.fill: parent
                            anchors.margins: 10
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = "#6b7280";
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                ctx.moveTo(width * 1 / 3, height * 1 / 3);
                                ctx.lineTo(width * 2 / 3, height * 2 / 3);
                                ctx.moveTo(width * 2 / 3, height * 1 / 3);
                                ctx.lineTo(width * 1 / 3, height * 2 / 3);
                                ctx.stroke();
                            }
                        }
                    }
                    
                    // 文字内容
                    Column {
                        spacing: 5
                        anchors.verticalCenter: parent.verticalCenter
                        
                        // 标题
                        Label {
                            text: "当前没有运行中的模型"
                            font.pointSize: 14
                            font.bold: true
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        // 描述
                        Label {
                            text: "启动模型后，这里将显示运行中的模型信息"
                            font.pointSize: 10
                            color: "#9ca3af"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
        
        // 运行中模型列表
        Column {
            id: activeModelsList
            x: 0
            y: 40
            width: parent.width
            height: parent.height - 40
            spacing: 15
            visible: activeModelsDetails.length > 0
            
            // 为每个运行中模型创建卡片
            Repeater {
                model: activeModelsDetails
                
                Rectangle {
                    width: parent.width
                    height: 100
                    color: "#1e1e1e"
                    radius: 12
                    border {
                        width: 1
                        color: "#333333"
                    }
                    
                    // 模型名称
                    Label {
                        x: 20
                        y: 20
                        width: parent.width - 140
                        height: 30
                        text: modelData.name
                        font.pointSize: 16
                        font.bold: true
                        color: "#ffffff"
                    }
                    
                    // 显存占用
                    Label {
                        x: 20
                        y: 60
                        width: 100
                        height: 20
                        text: {
                            var vram = modelData.size_vram || modelData.sizeVram || 0;
                            if (vram == 0) return "0 B";
                            if (vram < 1024 * 1024) return vram + " B";
                            if (vram < 1024 * 1024 * 1024) return (vram / (1024 * 1024)).toFixed(1) + " MB";
                            return (vram / (1024 * 1024 * 1024)).toFixed(1) + " GB";
                        }
                        font.pointSize: 12
                        color: "#9ca3af"
                    }
                    
                    // 保持时间
                    Label {
                        x: 150
                        y: 60
                        width: 100
                        height: 20
                        text: {
                            if (!modelData.expires_at && !modelData.expiresAt) return "无限制";
                            var expires_at = modelData.expires_at || modelData.expiresAt;
                            var now = new Date();
                            var expires = new Date(expires_at);
                            var diff = expires - now;
                            var minutes = Math.floor(diff / (1000 * 60));
                            return minutes + " 分钟";
                        }
                        font.pointSize: 12
                        color: "#9ca3af"
                    }
                    
                    // 磁盘占用
                    Label {
                        x: 280
                        y: 60
                        width: 100
                        height: 20
                        text: {
                            var disk = modelData.size || 0;
                            if (disk == 0) return "0 B";
                            if (disk < 1024 * 1024) return disk + " B";
                            if (disk < 1024 * 1024 * 1024) return (disk / (1024 * 1024)).toFixed(1) + " MB";
                            return (disk / (1024 * 1024 * 1024)).toFixed(1) + " GB";
                        }
                        font.pointSize: 12
                        color: "#9ca3af"
                    }
                    
                    // 卸载按钮
                    Rectangle {
                        x: parent.width - 100
                        y: 35
                        width: 70
                        height: 30
                        color: "#ef4444"
                        radius: 6
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                modelManager.unloadModel(modelData.name);
                            }
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: "卸载"
                            font.pointSize: 12
                            font.bold: true
                            color: "white"
                        }
                    }
                }
            }
        }
    }
}