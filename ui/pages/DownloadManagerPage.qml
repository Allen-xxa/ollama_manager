import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: downloadManagerPage
    property string currentPage: "downloadManager"
    property string deleteModelName: ""
    property bool showDeleteDialog: false
    width: parent.width
    height: parent.height
    color: "#121212"
    
    // 页面数据
    property var downloadTasks: []  // 下载任务列表
    property bool isLoading: false
    property string errorMessage: ""
    
    // 初始化
    Component.onCompleted: {
        // 直接从JSON文件加载下载任务
        loadDownloadTasksFromFile()
    }
    
    // 当页面可见时重新加载下载任务
    onVisibleChanged: {
        if (visible) {
            // 如果列表为空，从文件重新加载
            if (downloadTasks.length === 0) {
                loadDownloadTasksFromFile()
            }
        }
    }
    
    // 从JSON文件直接加载下载任务
    function loadDownloadTasksFromFile() {
        // 从modelManager直接读取JSON文件
        var tasks = modelManager.loadDownloadTasksFromFile()
        // console.log("loadDownloadTasksFromFile - tasks:", tasks)
        // console.log("loadDownloadTasksFromFile - tasks.length:", tasks ? tasks.length : 0)
        // console.log("loadDownloadTasksFromFile - tasks type:", typeof tasks)
        
        // 创建新数组并重新赋值，触发属性变化通知
        var newTasks = []
        if (tasks && tasks.length > 0) {
            // 添加所有下载任务
            for (var i = 0; i < tasks.length; i++) {
                // console.log("Adding task:", tasks[i])
                newTasks.push(tasks[i])
            }
        } else {
            // console.log("No tasks found or tasks is empty")
        }
        
        // 重新赋值整个数组，触发属性变化
        downloadTasks = newTasks
        // console.log("Final downloadTasks.length:", downloadTasks.length)
        
        isLoading = false
        errorMessage = ""
    }
    
    // 加载下载任务（保留用于实时更新）
    function loadDownloadTasks() {
        // 从modelManager获取当前的下载任务
        var tasks = modelManager.getDownloadTasks()
        
        // 创建新数组并重新赋值，触发属性变化通知
        var newTasks = []
        if (tasks && tasks.length > 0) {
            // 添加所有下载任务
            for (var i = 0; i < tasks.length; i++) {
                newTasks.push(tasks[i])
            }
        }
        
        // 重新赋值整个数组，触发属性变化
        downloadTasks = newTasks
        
        isLoading = false
        errorMessage = ""
    }
    
    // 删除下载任务
    function deleteDownload(modelName) {
        modelManager.cancelDownload(modelName)
    }
    
    // 暂停下载任务
    function pauseDownload(modelName) {
        modelManager.pauseDownload(modelName)
    }
    
    // 恢复下载任务
    function resumeDownload(modelName) {
        modelManager.resumeDownload(modelName)
    }
    
    // 显示删除确认对话框
    function showDeleteConfirmation(modelName) {
        deleteModelName = modelName
        showDeleteDialog = true
    }
    
    // 关闭删除确认对话框
    function closeDeleteDialog() {
        showDeleteDialog = false
        deleteModelName = ""
    }
    
    // 确认删除下载任务
    function confirmDelete() {
        deleteDownload(deleteModelName)
        closeDeleteDialog()
    }
    
    // 连接到modelManager的信号
    Connections {
        target: modelManager
        
        // 下载任务状态更新信号
        function onDownloadTaskUpdated(task) {
            // console.log("🔄 任务已更新:" + task.modelName + "状态:" + task.status)
            // 查找任务在列表中的位置
            var taskIndex = -1
            for (var i = 0; i < downloadTasks.length; i++) {
                if (downloadTasks[i].modelName === task.modelName) {
                    taskIndex = i
                    break
                }
            }
            
            // 创建新数组并重新赋值，触发属性变化通知
            var newTasks = []
            if (taskIndex !== -1) {
                // 更新现有任务
                for (var i = 0; i < downloadTasks.length; i++) {
                    if (i === taskIndex) {
                        newTasks.push(task)
                    } else {
                        newTasks.push(downloadTasks[i])
                    }
                }
                
                // 如果任务已完成或取消，从列表中移除
                if (task.status === "completed" || task.status === "cancelled") {
                    // console.log("🗑️  移除任务:" + task.modelName + "状态:" + task.status)
                    newTasks.splice(taskIndex, 1)
                }
            } else {
                // 添加新任务（非已完成或取消状态）
                if (task.status !== "completed" && task.status !== "cancelled") {
                    // console.log("➕ 添加新任务:" + task.modelName + "状态:" + task.status)
                    newTasks = downloadTasks.slice()
                    newTasks.push(task)
                } else {
                    newTasks = downloadTasks.slice()
                }
            }
        }
        
        // 下载进度更新信号
        function onDownloadProgressUpdated(modelName, progress, speed, eta) {
            // 查找并更新对应任务的进度
            var taskIndex = -1
            for (var i = 0; i < downloadTasks.length; i++) {
                if (downloadTasks[i].modelName === modelName) {
                    taskIndex = i
                    break
                }
            }
            
            if (taskIndex !== -1) {
                // 创建新数组并重新赋值，触发属性变化通知
                var newTasks = []
                for (var i = 0; i < downloadTasks.length; i++) {
                    if (i === taskIndex) {
                        // 更新找到的任务
                        var updatedTask = downloadTasks[i]
                        updatedTask.progress = progress
                        updatedTask.speed = speed
                        updatedTask.eta = eta
                        newTasks.push(updatedTask)
                    } else {
                        newTasks.push(downloadTasks[i])
                    }
                }
                
                // 重新赋值整个数组，触发属性变化
                downloadTasks = newTasks
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10
        
        // 标题行
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 20
            
            // 标题
            Label {
                Layout.minimumWidth: 100
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                text: "下载管理"
                font.pointSize: 20
                font.bold: true
                color: "#ffffff"
            }
            
            // 占位符，用于将内容推到右侧
            Item {
                Layout.fillWidth: true
            }
        }
        
        // 下载任务列表区域
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            
            // 加载状态
            Rectangle {
                id: loadingIndicator
                anchors.fill: parent
                color: "#121212"
                opacity: 0.8
                visible: isLoading
                
                Column {
                    anchors.centerIn: parent
                    spacing: 15
                    
                    // 加载动画
                    Canvas {
                        width: 40
                        height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        
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
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            
            // 错误信息
            Rectangle {
                id: errorIndicator
                anchors.fill: parent
                color: "transparent"
                visible: errorMessage !== ""
                
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    
                    Label {
                        text: errorMessage
                        color: "#ef4444"
                        font.pointSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    // 重试按钮
                    Rectangle {
                        width: 100
                        height: 36
                        color: "#3b82f6"
                        radius: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: loadDownloadTasks()
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
            
            // 下载任务列表
            Rectangle {
                id: tasksListContainer
                anchors.fill: parent
                color: "transparent"
                visible: !isLoading && errorMessage === "" && downloadTasks.length > 0
                
                Flickable {
                    id: tasksList
                    anchors.fill: parent
                    contentWidth: parent.width
                    contentHeight: contentColumn.height
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
                        id: contentColumn
                        width: parent.width
                        spacing: 15
                        
                        Repeater {
                            model: downloadTasks
                            
                            Rectangle {
                                width: parent.width
                                height: 150
                                color: "#1e1e1e"
                                radius: 12
                                border {
                                    width: 1
                                    color: "#333333"
                                }
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    spacing: 10
                                    
                                    // 模型名称和状态
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        spacing: 10
                                        
                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.modelName
                                            font.pointSize: 16
                                            font.bold: true
                                            color: "#ffffff"
                                            elide: Text.ElideRight
                                        }
                                        
                                        Label {
                                            text: modelData.status === "downloading" ? "下载中" : 
                                                  modelData.status === "queued" ? "排队中" : 
                                                  modelData.status === "paused" ? "已暂停" :
                                                  modelData.status === "completed" ? "已完成" : 
                                                  modelData.status === "failed" ? "失败" : "未知"
                                            font.pointSize: 12
                                            color: modelData.status === "downloading" ? "#3b82f6" : 
                                                  modelData.status === "queued" ? "#f59e0b" : 
                                                  modelData.status === "paused" ? "#f59e0b" :
                                                  modelData.status === "completed" ? "#10b981" : 
                                                  modelData.status === "failed" ? "#ef4444" : "#9ca3af"
                                        }
                                    }
                                    
                                    // 文件大小信息
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 20
                                        spacing: 10
                                        
                                        Label {
                                            text: "文件大小: " + (modelData.totalSize ? modelData.totalSize : "计算中...")
                                            font.pointSize: 12
                                            color: "#9ca3af"
                                        }
                                        
                                        Label {
                                            text: "已下载: " + (modelData.downloadedSize ? modelData.downloadedSize : "0 B")
                                            font.pointSize: 12
                                            color: "#9ca3af"
                                        }
                                    }
                                    
                                    // 下载速度和预计时间
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 20
                                        spacing: 10
                                        
                                        Label {
                                            text: "速度: " + (modelData.speed ? modelData.speed : "0 B/s")
                                            font.pointSize: 12
                                            color: "#9ca3af"
                                        }
                                        
                                        Label {
                                            text: "预计剩余: " + (modelData.eta ? modelData.eta : "计算中...")
                                            font.pointSize: 12
                                            color: "#9ca3af"
                                        }
                                    }
                                    
                                    // 进度条
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 8
                                        color: "#333333"
                                        radius: 4
                                        
                                        Rectangle {
                                            width: parent.width * (modelData.progress ? modelData.progress / 100 : 0)
                                            height: parent.height
                                            color: "#3b82f6"
                                            radius: 4
                                        }
                                        
                                        Label {
                                            anchors.centerIn: parent
                                            text: Math.round(modelData.progress ? modelData.progress : 0) + "%"
                                            font.pointSize: 10
                                            color: "#ffffff"
                                        }
                                    }
                                    
                                    // 操作按钮
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        spacing: 10
                                        
                                        Item {
                                            Layout.fillWidth: true
                                        }
                                        
                                        // 暂停/恢复按钮（仅当下载中、排队中或暂停时显示）
                                        Rectangle {
                                            width: 100
                                            height: 36
                                            color: modelData.status === "downloading" || modelData.status === "queued" ? "#f59e0b" : "#10b981"
                                            radius: 6
                                            visible: modelData.status === "downloading" || modelData.status === "paused" || modelData.status === "queued"
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if (modelData.status === "downloading" || modelData.status === "queued") {
                                                        pauseDownload(modelData.modelName)
                                                    } else if (modelData.status === "paused") {
                                                        resumeDownload(modelData.modelName)
                                                    }
                                                }
                                            }
                                            
                                            Label {
                                                anchors.centerIn: parent
                                                text: modelData.status === "downloading" || modelData.status === "queued" ? "暂停" : "恢复"
                                                color: "#ffffff"
                                                font.pointSize: 12
                                                font.bold: true
                                            }
                                        }
                                        
                                        // 重试按钮（仅当失败时显示）
                                        Rectangle {
                                            width: 100
                                            height: 36
                                            color: "#3b82f6"
                                            radius: 6
                                            visible: modelData.status === "failed"
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    resumeDownload(modelData.modelName)
                                                }
                                            }
                                            
                                            Label {
                                                anchors.centerIn: parent
                                                text: "重试"
                                                color: "#ffffff"
                                                font.pointSize: 12
                                                font.bold: true
                                            }
                                        }
                                        
                                        // 删除下载按钮
                                        Rectangle {
                                            width: 100
                                            height: 36
                                            color: "#ef4444"
                                            radius: 6
                                            visible: modelData.status !== "completed"
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    showDeleteConfirmation(modelData.modelName)
                                                }
                                            }
                                            
                                            Label {
                                                anchors.centerIn: parent
                                                text: "删除"
                                                color: "#ffffff"
                                                font.pointSize: 12
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // 空状态
            Rectangle {
                id: emptyState
                anchors.fill: parent
                color: "transparent"
                visible: !isLoading && errorMessage === "" && downloadTasks.length === 0
                
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    
                    Label {
                        text: "暂无下载任务"
                        color: "#9ca3af"
                        font.pointSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    Label {
                        text: "从模型库中拉取模型后，任务会显示在这里"
                        color: "#6b7280"
                        font.pointSize: 12
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
    
    // 删除确认对话框
    Item {
        id: deleteDialogOverlay
        visible: showDeleteDialog
        anchors.fill: parent
        z: 9999
        
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.5
            
            MouseArea {
                anchors.fill: parent
                onClicked: closeDeleteDialog()
            }
        }
        
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
                
                Label {
                    Layout.fillWidth: true
                    text: "删除下载任务"
                    font.pointSize: 16
                    font.bold: true
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Label {
                    Layout.fillWidth: true
                    text: "确定要删除 " + deleteModelName + " 吗？"
                    font.pointSize: 14
                    color: "#9ca3af"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    
                    Item {
                        Layout.fillWidth: true
                    }
                    
                    Rectangle {
                        width: 100
                        height: 40
                        color: "#2a2a2a"
                        radius: 8
                        border {
                            width: 1
                            color: "#333333"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: closeDeleteDialog()
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: "取消"
                            color: "#ffffff"
                            font.pointSize: 14
                        }
                    }
                    
                    Rectangle {
                        width: 100
                        height: 40
                        color: "#ff6b6b"
                        radius: 8
                        border {
                            width: 1
                            color: "#ff8787"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: confirmDelete()
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: "确认"
                            color: "#ffffff"
                            font.pointSize: 14
                            font.bold: true
                        }
                    }
                    
                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}