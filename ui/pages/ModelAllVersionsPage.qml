import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: modelAllVersionsPage
    property string currentPage: "modelAllVersions"
    width: parent.width
    height: parent.height
    color: "#121212"
    // 页面导航信号
    signal pageChanged(string page)
    
    // 页面数据
    property var currentModelData: null
    property var modelVersions: []
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
            loadAllVersions()
        } else {
            errorMessage = "未找到模型数据"
        }
    }
    
    // 加载所有版本
    function loadAllVersions() {
        if (!currentModelData) return
        
        isLoading = true
        errorMessage = ""
        
        // 调用模型管理器获取所有版本
        modelManager.getModelAllVersions(currentModelData.name)
    }
    
    // 返回模型详情页
    function goBack() {
        // 发送页面变更信号
        modelAllVersionsPage.pageChanged("modelDetail")
    }
    
    // 顶部导航栏
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 70
        spacing: 15
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        
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
            text: currentModelData ? currentModelData.display_name + " - 所有版本" : "所有版本"
            font.pointSize: 18
            font.bold: true
            color: "#ffffff"
        }
    }
    
    // 页面滚动容器
        Flickable {
            id: pageFlickable
            anchors.fill: parent
            anchors.topMargin: 80
            anchors.margins: 20
            contentWidth: parent.width - 30 // 固定宽度，避免循环绑定
            contentHeight: mainColumn.height
            clip: true
            
            // 垂直滚动条
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
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
            
            ColumnLayout {
                id: mainColumn
                width: pageFlickable.width // 明确绑定到 Flickable 宽度，避免循环
                spacing: 20
        
        // 版本部分
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 110 + (modelVersions.length * 50)
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
                    
                    Label {
                        text: "所有版本"
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
                        onClicked: loadAllVersions()
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
    }
    
    // 加载状态 - 改为类似设置页保存提示的样式
    Rectangle {
        id: loadingIndicator
        width: 200
        height: 50
        color: "#3b82f6"
        radius: 8
        border {
            width: 1
            color: "#60a5fa"
        }
        opacity: 1
        visible: isLoading
        anchors.centerIn: parent
        z: 9999
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10
            
            // 加载动画
            Canvas {
                width: 20
                height: 20
                Layout.alignment: Qt.AlignVCenter
                
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = "#ffffff"
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.arc(width/2, height/2, width/3, 0, Math.PI*2)
                    ctx.stroke()
                }
            }
            
            Label {
                text: "加载中..."
                color: "#ffffff"
                font.pointSize: 14
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
    
    // 拉取提示弹窗 - 放在 modelAllVersionsPage 内部，使用覆盖层方式实现
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
                            // 不跳转到下载管理页面
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
    
    // 监听模型所有版本更新信号
    Connections {
        target: modelManager
        
        function onModelAllVersionsUpdated(versions) {
            modelVersions = versions
            isLoading = false
        }
        
        function onModelAllVersionsStatusUpdated(status) {
            if (status.includes("失败")) {
                errorMessage = status
                isLoading = false
            }
        }
    }
}