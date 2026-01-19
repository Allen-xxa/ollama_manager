import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: modelDetailPage
    property string currentPage: "modelDetail"
    width: parent.width
    height: parent.height
    color: "#121212"
    // 页面导航信号
    signal pageChanged(string page)
    
    // 页面数据
    property var currentModelData: null
    property var modelVersions: []
    property var modelDescription: ""
    property bool isLoading: false
    property string errorMessage: ""
    property bool showPullDialog: false  // 控制拉取提示弹窗显示
    
    // 显示拉取提示弹窗
    function showPullConfirmation(modelName) {
        // 调用模型管理器拉取模型
        modelManager.pullModel(modelName)
        // 显示拉取提示弹窗
        showPullDialog = true
    }
    
    // 关闭拉取提示弹窗
    function closePullDialog() {
        showPullDialog = false
    }
    
    // 初始化
    Component.onCompleted: {
        if (modelManager.currentModel) {
            currentModelData = modelManager.currentModel
            console.log("Model data loaded:", currentModelData)
            loadModelDetails()
        } else {
            errorMessage = "未找到模型数据"
        }
    }
    
    // 加载模型详情
    function loadModelDetails() {
        if (!currentModelData) return
        
        isLoading = true
        errorMessage = ""
        
        // 调用模型管理器获取详情
        modelManager.getModelDetails(currentModelData.link)
    }
    
    // 返回模型列表
    function goBack() {
        // 发送页面变更信号
        modelDetailPage.pageChanged("modelLibrary")
        console.log("Page changed signal sent for modelLibrary")
    }
    
    // 监听模型详情更新信号
    Connections {
        target: modelManager
        
        function onModelDetailsUpdated(versions, description) {
            modelVersions = versions
            modelDescription = description
            isLoading = false
            console.log("Model details updated. Versions:", versions.length)
            
            // 添加详细的调试信息
            for (var i = 0; i < versions.length; i++) {
                var version = versions[i]
                console.log("Version", i + 1, ":", JSON.stringify(version))
            }
        }
        
        function onModelDetailsStatusUpdated(status) {
            console.log("Model details status:", status)
            if (status.includes("失败")) {
                errorMessage = status
                isLoading = false
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        // 顶部导航栏
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 15
            
            // 返回按钮
            Rectangle {
                width: 40
                height: 40
                color: "#1e1e1e"
                radius: 8
                border {
                    width: 1
                    color: "#333333"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: goBack()
                }
                
                Canvas {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = "#ffffff"
                        ctx.lineWidth = 2
                        ctx.beginPath()
                        ctx.moveTo(width * 0.7, height * 0.3)
                        ctx.lineTo(width * 0.3, height * 0.5)
                        ctx.lineTo(width * 0.7, height * 0.7)
                        ctx.stroke()
                    }
                }
            }
            
            // 标题
            Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: currentModelData ? currentModelData.display_name : "模型详情"
                font.pointSize: 18
                font.bold: true
                color: "#ffffff"
            }
        }
        
        // 模型卡
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: "#1e1e1e"
            radius: 12
            border {
                width: 1
                color: "#333333"
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15
                
                // 模型图标
                Rectangle {
                    width: 60
                    height: 60
                    color: "#333333"
                    radius: 12
                    Layout.alignment: Qt.AlignVCenter
                    
                    Canvas {
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = "#3b82f6"
                            ctx.lineWidth = 2
                            ctx.beginPath()
                            ctx.moveTo(width * 0.2, height * 0.2)
                            ctx.lineTo(width * 0.8, height * 0.2)
                            ctx.lineTo(width * 0.8, height * 0.8)
                            ctx.lineTo(width * 0.2, height * 0.8)
                            ctx.closePath()
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(width * 0.4, height * 0.2)
                            ctx.lineTo(width * 0.4, height * 0.8)
                            ctx.lineTo(width * 0.6, height * 0.8)
                            ctx.lineTo(width * 0.6, height * 0.2)
                            ctx.closePath()
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(width * 0.2, height * 0.4)
                            ctx.lineTo(width * 0.8, height * 0.4)
                            ctx.lineTo(width * 0.8, height * 0.6)
                            ctx.lineTo(width * 0.2, height * 0.6)
                            ctx.closePath()
                            ctx.stroke()
                        }
                    }
                }
                
                // 模型信息
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8
                    
                    // 模型名称
                    Label {
                        Layout.fillWidth: true
                        text: currentModelData ? currentModelData.display_name : "未知模型"
                        font.pointSize: 16
                        font.bold: true
                        color: "#ffffff"
                        elide: Text.ElideRight
                    }
                    
                    // 模型描述
                    Label {
                        Layout.fillWidth: true
                        text: currentModelData ? currentModelData.description : "无描述"
                        font.pointSize: 12
                        color: "#9ca3af"
                        elide: Text.ElideRight
                    }
                    
                    // 模型统计
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20
                        
                        Label {
                            text: "下载量: " + (currentModelData ? currentModelData.pull_count_formatted : "0")
                            font.pointSize: 10
                            color: "#6b7280"
                        }
                        
                        Label {
                            text: "更新时间: " + (currentModelData ? currentModelData.updated_at : "未知")
                            font.pointSize: 10
                            color: "#6b7280"
                        }
                    }
                }
            }
        }
        
        // 版本部分
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100 + (modelVersions.length * 50)
            color: "#1e1e1e"
            radius: 12
            border {
                width: 1
                color: "#333333"
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15
                
                // 标题
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Canvas {
                        width: 20
                        height: 20
                        Layout.alignment: Qt.AlignVCenter
                        
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = "#3b82f6"
                            ctx.lineWidth = 2
                            ctx.beginPath()
                            ctx.moveTo(width * 0.2, height * 0.2)
                            ctx.lineTo(width * 0.8, height * 0.2)
                            ctx.lineTo(width * 0.8, height * 0.8)
                            ctx.lineTo(width * 0.2, height * 0.8)
                            ctx.closePath()
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(width * 0.2, height * 0.5)
                            ctx.lineTo(width * 0.8, height * 0.5)
                            ctx.stroke()
                        }
                    }
                    
                    Label {
                        text: "版本"
                        font.pointSize: 14
                        font.bold: true
                        color: "#ffffff"
                    }
                }
                
                // 版本列表
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    
                    Flickable {
                            anchors.fill: parent
                            contentWidth: parent.width
                            contentHeight: versionsColumn.height
                            clip: true
                            interactive: false
                        
                        Column {
                            id: versionsColumn
                            width: parent.width
                            spacing: 10
                            
                            // 表头
                            Row {
                                width: parent.width
                                height: 36
                                spacing: 10
                                
                                Label {
                                    width: parent.width - 590
                                    height: parent.height
                                    font.pointSize: 12
                                    font.bold: true
                                    color: "#9ca3af"
                                    verticalAlignment: Text.AlignVCenter
                                    // 使用textFormat和Html格式添加内边距
                                    textFormat: Text.RichText
                                    text: "<span style='padding-left: 10px;'>名称</span>"
                                }
                                
                                Label {
                                    width: 150
                                    height: parent.height
                                    text: "文件大小"
                                    font.pointSize: 12
                                    font.bold: true
                                    color: "#9ca3af"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                
                                Label {
                                    width: 150
                                    height: parent.height
                                    text: "上下文"
                                    font.pointSize: 12
                                    font.bold: true
                                    color: "#9ca3af"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                
                                Label {
                                    width: 150
                                    height: parent.height
                                    text: "输入类型"
                                    font.pointSize: 12
                                    font.bold: true
                                    color: "#9ca3af"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                
                                Label {
                                    width: 100
                                    height: parent.height
                                    text: "操作"
                                    font.pointSize: 12
                                    font.bold: true
                                    color: "#9ca3af"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            
                            // 版本数据
                            Repeater {
                                model: modelVersions
                                delegate: Row {
                                    width: parent.width
                                    height: 40
                                    spacing: 10
                                    
                                    Label {
                                        width: parent.width - 590
                                        height: parent.height
                                        text: modelData.version ? ((currentModelData && currentModelData.name) ? currentModelData.name + ":" + modelData.version : "未知版本") : ((currentModelData && currentModelData.name) ? currentModelData.name : "未知版本")
                                        font.pointSize: 12
                                        color: "#ffffff"
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                    
                                    Label {
                                        width: 150
                                        height: parent.height
                                        text: modelData.size ? modelData.size : "未知"
                                        font.pointSize: 12
                                        color: "#9ca3af"
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    
                                    Label {
                                        width: 150
                                        height: parent.height
                                        text: modelData.context ? modelData.context : "未知"
                                        font.pointSize: 12
                                        color: "#9ca3af"
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    
                                    Label {
                                        width: 150
                                        height: parent.height
                                        text: modelData.input ? modelData.input : "未知"
                                        font.pointSize: 12
                                        color: "#9ca3af"
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    
                                    Item {
                                        width: 100
                                        height: parent.height
                                        
                                        Rectangle {
                                            width: 80
                                            height: 32
                                            color: "#3b82f6"
                                            radius: 6
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.verticalCenter: parent.verticalCenter
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if (currentModelData) {
                                                        var fullModelName = currentModelData.name
                                                        if (modelData.version) {
                                                            fullModelName += ":" + modelData.version
                                                        }
                                                        console.log("Pull model:", fullModelName)
                                                        // 显示拉取提示弹窗
                                                        showPullConfirmation(fullModelName)
                                                    }
                                                }
                                            }
                                            
                                            Label {
                                                anchors.centerIn: parent
                                                text: "拉取"
                                                color: "#ffffff"
                                                font.pointSize: 11
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // 空状态
                            Rectangle {
                                width: parent.width
                                height: 100
                                color: "transparent"
                                visible: modelVersions.length === 0 && !isLoading && errorMessage === ""
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: "未找到版本信息"
                                    color: "#9ca3af"
                                    font.pointSize: 14
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 描述部分
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 300
            color: "#1e1e1e"
            radius: 12
            border {
                width: 1
                color: "#333333"
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15
                
                // 标题
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Canvas {
                        width: 20
                        height: 20
                        Layout.alignment: Qt.AlignVCenter
                        
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = "#3b82f6"
                            ctx.lineWidth = 2
                            ctx.beginPath()
                            ctx.arc(width * 0.5, height * 0.5, width * 0.4, 0, Math.PI * 2)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(width * 0.5, height * 0.2)
                            ctx.lineTo(width * 0.5, height * 0.8)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(width * 0.2, height * 0.5)
                            ctx.lineTo(width * 0.8, height * 0.5)
                            ctx.stroke()
                        }
                    }
                    
                    Label {
                        text: "描述"
                        font.pointSize: 14
                        font.bold: true
                        color: "#ffffff"
                    }
                }
                
                // 描述内容
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    
                    Flickable {
                        anchors.fill: parent
                        contentWidth: parent.width
                        contentHeight: descriptionContent.height
                        clip: true
                        interactive: contentHeight > height
                        
                        // 垂直滚动条
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AlwaysOn
                            width: 8
                            hoverEnabled: true
                            
                            background: Rectangle {
                                color: "#1e1e1e"
                                radius: 4
                            }
                            
                            contentItem: Rectangle {
                                color: "#3b82f6"
                                radius: 4
                            }
                        }
                        
                        Column {
                            id: descriptionContent
                            width: parent.width
                            spacing: 15
                            
                            // 模型描述文本
                            Label {
                                width: parent.width
                                text: modelDescription || (currentModelData ? currentModelData.description : "无详细描述")
                                font.pointSize: 12
                                color: "#9ca3af"
                                wrapMode: Text.WordWrap
                                lineHeight: 1.4
                            }
                            
                            // 示例图表区域（模拟）
                            Rectangle {
                                width: parent.width
                                height: 200
                                color: "#1a1a1a"
                                radius: 8
                                border {
                                    width: 1
                                    color: "#2d2d2d"
                                }
                                
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    spacing: 10
                                    
                                    Label {
                                        width: parent.width
                                        text: "模型性能对比"
                                        font.pointSize: 14
                                        font.bold: true
                                        color: "#ffffff"
                                    }
                                    
                                    // 模拟图表
                                    Canvas {
                                        width: parent.width
                                        height: 150
                                        
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)
                                            
                                            // 绘制坐标轴
                                            ctx.strokeStyle = "#333333"
                                            ctx.lineWidth = 1
                                            ctx.beginPath()
                                            ctx.moveTo(50, 10)
                                            ctx.lineTo(50, height - 10)
                                            ctx.lineTo(width - 10, height - 10)
                                            ctx.stroke()
                                            
                                            // 绘制柱状图
                                            var bars = [
                                                { name: "Model A", value: 85, color: "#3b82f6" },
                                                { name: "Model B", value: 75, color: "#10b981" },
                                                { name: "Model C", value: 65, color: "#f59e0b" }
                                            ]
                                            
                                            var barWidth = (width - 120) / bars.length
                                            var barSpacing = 20
                                            
                                            for (var i = 0; i < bars.length; i++) {
                                                var barHeight = (bars[i].value / 100) * (height - 40)
                                                var x = 70 + i * (barWidth + barSpacing)
                                                var y = height - 10 - barHeight
                                                
                                                ctx.fillStyle = bars[i].color
                                                ctx.fillRect(x, y, barWidth, barHeight)
                                                
                                                ctx.fillStyle = "#9ca3af"
                                                ctx.font = "10px Arial"
                                                ctx.textAlign = "center"
                                                ctx.fillText(bars[i].name, x + barWidth / 2, height - 2)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 加载状态
        Rectangle {
            id: loadingIndicator
            width: parent.width
            height: parent.height
            color: "#121212"
            opacity: 0.8
            visible: isLoading
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 15
                
                // 加载动画
                Canvas {
                    width: 40
                    height: 40
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = "#3b82f6"
                        ctx.lineWidth = 3
                        ctx.beginPath()
                        ctx.arc(width/2, height/2, width/3, 0, Math.PI*2)
                        ctx.stroke()
                    }
                }
                
                Label {
                    text: "加载中..."
                    color: "#ffffff"
                    font.pointSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
        
        // 错误信息
        Rectangle {
            id: errorIndicator
            width: parent.width
            height: parent.height
            color: "transparent"
            visible: errorMessage !== ""
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Label {
                    text: errorMessage
                    color: "#ef4444"
                    font.pointSize: 14
                    Layout.alignment: Qt.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                
                // 重试按钮
                Rectangle {
                    width: 100
                    height: 36
                    color: "#3b82f6"
                    radius: 6
                    Layout.alignment: Qt.AlignHCenter
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: loadModelDetails()
                    }
                    
                    Label {
                        anchors.centerIn: parent
                        text: "重试"
                        color: "#ffffff"
                        font.pointSize: 12
                        font.bold: true
                    }
                }
            }
        }
    }
    
    // 拉取提示弹窗 - 放在 modelDetailPage 内部，使用覆盖层方式实现
    Item {
        id: pullDialogOverlay
        visible: showPullDialog
        anchors.fill: parent
        z: 9999
        
        // 背景遮罩
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.5
            
            MouseArea {
                anchors.fill: parent
                onClicked: closePullDialog()
            }
        }
        
        // 弹窗内容
        Rectangle {
            width: 400
            height: 200
            color: "#1e1e1e"
            radius: 12
            border {
                width: 1
                color: "#333333"
            }
            anchors.centerIn: parent
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20
                
                // 标题
                Label {
                    Layout.fillWidth: true
                    text: "拉取模型"
                    font.pointSize: 16
                    font.bold: true
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // 提示信息
                Label {
                    Layout.fillWidth: true
                    text: "已加入下载队列，请在下载管理页面查看进度"
                    font.pointSize: 14
                    color: "#9ca3af"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                
                // 确定按钮
                Rectangle {
                    width: 120
                    height: 40
                    color: "#3b82f6"
                    radius: 8
                    Layout.alignment: Qt.AlignHCenter
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            closePullDialog()
                        }
                    }
                    
                    Label {
                        anchors.centerIn: parent
                        text: "确定"
                        color: "#ffffff"
                        font.pointSize: 14
                        font.bold: true
                    }
                }
            }
        }
    }
}