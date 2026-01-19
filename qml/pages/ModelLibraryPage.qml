import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: modelLibraryPage
    property string currentPage: "modelManager"
    width: parent.width
    height: parent.height
    color: "#121212"
    // 页面导航信号
    signal pageChanged(string page)
    
    // 页面数据
    property int currentPageNum: 1
    property int pageSize: 10
    property int totalModels: 0
    property int totalPages: 0
    property string searchText: ""
    property var modelLibrary: []
    property var displayModels: []  // 当前页要显示的模型
    property bool isLoading: false
    property string errorMessage: ""
    
    // 初始化
    Component.onCompleted: {
        loadModels()
    }
    
    // 加载模型列表
    function loadModels() {
        isLoading = true
        errorMessage = ""
        modelManager.getModelLibrary(1, 100, searchText)  // 获取更多模型
    }
    
    // 计算总页数
    function updateTotalPages() {
        totalPages = Math.ceil(totalModels / pageSize)
        // 确保至少有1页
        if (totalPages === 0 && modelLibrary.length > 0) {
            totalPages = 1
        }
        // 更新当前页显示的模型
        updateDisplayModels()
    }
    
    // 更新当前页显示的模型
    function updateDisplayModels() {
        var startIndex = (currentPageNum - 1) * pageSize
        var endIndex = startIndex + pageSize
        displayModels = modelLibrary.slice(startIndex, endIndex)
    }
    
    // 监听模型库更新信号
    Connections {
        target: modelManager
        
        function onModelLibraryUpdated(models, total) {
            // 为每个模型添加displayDescription属性
            for (let i = 0; i < models.length; i++) {
                models[i].displayDescription = models[i].description;
            }
            
            modelLibrary = models
            totalModels = models.length // 使用实际获取的模型数量
            updateTotalPages()
            isLoading = false
        }
        
        function onModelLibraryStatusUpdated(status) {
            console.log("Model library status:", status)
            if (status.includes("失败")) {
                errorMessage = status
                isLoading = false
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10
        
        // 标题和搜索框行
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 20
            
            // 标题
            Label {
                Layout.minimumWidth: 100
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                text: "热门模型"
                font.pointSize: 20
                font.bold: true
                color: "#ffffff"
            }
            
            // 占位符，用于将搜索框推到右侧
            Item {
                Layout.fillWidth: true
            }
            
            // 搜索框
            Rectangle {
                width: 300
                height: 40
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                color: "#1e1e1e"
                radius: 8
                border {
                    width: 1
                    color: "#333333"
                }
                
                Row {
                    width: parent.width
                    height: parent.height
                    spacing: 10
                    
                    // 搜索图标
                    Item {
                        width: 40
                        height: parent.height
                        
                        Canvas {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.strokeStyle = "#9ca3af"
                                ctx.lineWidth = 2
                                ctx.beginPath()
                                ctx.arc(width * 0.5, height * 0.5, width * 0.3, 0, Math.PI * 2)
                                ctx.stroke()
                                ctx.beginPath()
                                ctx.moveTo(width * 0.7, height * 0.7)
                                ctx.lineTo(width * 0.9, height * 0.9)
                                ctx.stroke()
                            }
                        }
                    }
                    
                    // 搜索输入框
                    TextField {
                        id: searchTextField
                        width: parent.width - 90
                        height: parent.height
                        color: "#ffffff"
                        placeholderText: "搜索模型..."
                        placeholderTextColor: "#6b7280"
                        background: Rectangle {
                            color: "transparent"
                        }
                        onAccepted: {
                            searchText = searchTextField.text
                            currentPageNum = 1 // 搜索时重置到第一页
                            loadModels()
                        }
                    }
                    
                    // 搜索按钮
                    Rectangle {
                        width: 40
                        height: parent.height
                        radius: 6
                        color: "#3b82f6"
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchText = searchTextField.text
                                currentPageNum = 1 // 搜索时重置到第一页
                                loadModels()
                            }
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
                                ctx.arc(width * 0.5, height * 0.5, width * 0.3, 0, Math.PI * 2)
                                ctx.stroke()
                                ctx.beginPath()
                                ctx.moveTo(width * 0.7, height * 0.7)
                                ctx.lineTo(width * 0.9, height * 0.9)
                                ctx.stroke()
                            }
                        }
                    }
                }
            }
        }
        
        // 模型列表区域
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
                            onClicked: loadModels()
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
            
            // 模型列表
            Rectangle {
                id: modelsListContainer
                anchors.fill: parent
                color: "transparent"
                visible: !isLoading && errorMessage === "" && displayModels.length > 0
                
                Flickable {
                    id: modelsList
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
                            model: displayModels
                            
                            Rectangle {
                                width: parent.width
                                height: 130
                                color: "#1e1e1e"
                                radius: 12
                                border {
                                    width: 1
                                    color: "#333333"
                                }
                                
                                Row {
                                    width: parent.width
                                    height: parent.height
                                    spacing: 20
                                    
                                    // 模型信息
                                    Item {
                                        width: parent.width - 150
                                        height: parent.height
                                        
                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 15
                                            spacing: 10
                                            
                                            // 模型名称
                                            Label {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                text: modelData.display_name
                                                font.pointSize: 16
                                                font.bold: true
                                                color: "#ffffff"
                                                elide: Text.ElideRight
                                            }
                                            
                                            // 模型描述和翻译按钮
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: 10
                                                
                                                // 翻译按钮
                                                Rectangle {
                                                    width: 32
                                                    height: 32
                                                    radius: 16
                                                    color: "#3b82f6"
                                                    
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            console.log("Translation button clicked for model:", modelData.display_name);
                                                            console.log("Current displayDescription:", modelData.displayDescription);
                                                            console.log("Original description:", modelData.description);
                                                            
                                                            // 切换翻译状态
                                                            if (modelData.displayDescription === modelData.description) {
                                                                console.log("Translating to Chinese:", modelData.description);
                                                                // 翻译为中文
                                                                var translated = modelManager.translateDescription(modelData.description);
                                                                console.log("Translated result:", translated);
                                                                
                                                                // 更新模型数据
                                                                var modelIndex = modelLibrary.findIndex(function(m) {
                                                                    return m.name === modelData.name;
                                                                });
                                                                
                                                                if (modelIndex !== -1) {
                                                                    console.log("Updating model at index:", modelIndex);
                                                                    modelLibrary[modelIndex].displayDescription = translated;
                                                                    // 强制更新displayModels
                                                                    updateDisplayModels();
                                                                    console.log("Model updated successfully");
                                                                } else {
                                                                    console.log("Model not found in library");
                                                                }
                                                            } else {
                                                                console.log("Restoring to English");
                                                                // 恢复英文
                                                                var modelIndex = modelLibrary.findIndex(function(m) {
                                                                    return m.name === modelData.name;
                                                                });
                                                                
                                                                if (modelIndex !== -1) {
                                                                    modelLibrary[modelIndex].displayDescription = modelLibrary[modelIndex].description;
                                                                    // 强制更新displayModels
                                                                    updateDisplayModels();
                                                                    console.log("Restored to original description");
                                                                }
                                                            }
                                                        }
                                                    }
                                                    
                                                    Image {
                                                        anchors.centerIn: parent
                                                        width: 24
                                                        height: 24
                                                        source: "../img/trans.png"
                                                        fillMode: Image.PreserveAspectFit
                                                    }
                                                }
                                                
                                                // 模型描述
                                                Label {
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter
                                                    text: modelData.displayDescription || modelData.description
                                                    font.pointSize: 12
                                                    color: "#9ca3af"
                                                    elide: Text.ElideRight
                                                    wrapMode: Text.WordWrap
                                                    Layout.maximumHeight: 40
                                                }
                                            }
                                            
                                            // 模型统计信息
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: 20
                                                
                                                Label {
                                                    text: "下载量: " + (modelData.pull_count_formatted || "0")
                                                    font.pointSize: 10
                                                    color: "#6b7280"
                                                }
                                                
                                                Label {
                                                    text: "更新时间: " + (modelData.updated_at || "未知")
                                                    font.pointSize: 10
                                                    color: "#6b7280"
                                                }
                                            }
                                        }
                                    }
                                    
                                    // 操作按钮
                                    Item {
                                        width: 100
                                        height: 36
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        Rectangle {
                                            anchors.fill: parent
                                            color: "#3b82f6"
                                            radius: 6
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    console.log("Query model details:", modelData.name)
                                                    console.log("Model link:", modelData.link)
                                                    // 存储当前模型数据
                                                    modelManager.setCurrentModel(modelData)
                                                    // 发送页面变更信号
                                                    modelLibraryPage.pageChanged("modelDetail")
                                                    console.log("Page changed signal sent for modelDetail")
                                                }
                                            }
                                            
                                            Label {
                                                anchors.centerIn: parent
                                                text: "查询"
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
                visible: !isLoading && errorMessage === "" && displayModels.length === 0
                
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    
                    Label {
                        text: searchText ? "未找到匹配的模型" : "模型库为空"
                        color: "#9ca3af"
                        font.pointSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
        
        // 分页控件
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.alignment: Qt.AlignCenter
            spacing: 10
            
            // 上一页按钮
            Rectangle {
                width: 80
                height: 36
                color: currentPageNum > 1 ? "#1e1e1e" : "#1a1a1a"
                radius: 6
                border {
                    width: 1
                    color: currentPageNum > 1 ? "#333333" : "#2a2a2a"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (currentPageNum > 1) {
                            currentPageNum--
                            updateDisplayModels()
                        }
                    }
                    enabled: currentPageNum > 1
                }
                
                Label {
                    anchors.centerIn: parent
                    text: "上一页"
                    color: currentPageNum > 1 ? "#ffffff" : "#6b7280"
                    font.pointSize: 12
                }
            }
            
            // 页码显示
            Label {
                Layout.alignment: Qt.AlignCenter
                text: "第 " + currentPageNum + " 页，共 " + totalPages + " 页"
                color: "#9ca3af"
                font.pointSize: 12
            }
            
            // 下一页按钮
            Rectangle {
                width: 80
                height: 36
                color: currentPageNum < totalPages ? "#1e1e1e" : "#1a1a1a"
                radius: 6
                border {
                    width: 1
                    color: currentPageNum < totalPages ? "#333333" : "#2a2a2a"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (currentPageNum < totalPages) {
                            currentPageNum++
                            updateDisplayModels()
                        }
                    }
                    enabled: currentPageNum < totalPages
                }
                
                Label {
                    anchors.centerIn: parent
                    text: "下一页"
                    color: currentPageNum < totalPages ? "#ffffff" : "#6b7280"
                    font.pointSize: 12
                }
            }
        }
    }
}