import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    width: 200
    height: parent.height
    color: "#1e1e1e"
    border {
        width: 1
        color: "#333333"
    }
    radius: 0
    z: 0

    property string currentPage: "dashboard"
    signal pageChanged(string page)
    
    // 存储活跃服务器信息
    property var activeServer: null
    property bool isServerConnected: false
    property bool isTestingConnection: false
    property string statusMessage: "就绪"  // 状态描述信息
    property real serverLatency: 0  // 服务器延迟（毫秒）
    
    // 连接到modelManager获取活跃服务器信息
    Connections {
        target: modelManager
        function onServersUpdated() {
            if (modelManager) {
                updateActiveServer()
                // 服务器列表更新后，延迟一小段时间再测试连接
                // 这样可以确保活跃服务器已经正确更新
                Qt.callLater(function() {
                    if (modelManager && activeServer) {
                        testServerConnectionAsync(activeServer.address, activeServer.port)
                    }
                })
            }
        }
        
        // 连接服务器连接测试结果信号
        function onServerConnectionTested(isConnected, latency) {
            isServerConnected = isConnected
            isTestingConnection = false
            serverLatency = latency
            statusMessage = isConnected ? `连接成功 (${latency.toFixed(1)}ms)` : "连接失败"
        }
        
        // 连接状态更新信号
        function onStatusUpdated(status) {
            statusMessage = status
            // 只有当状态不是"连接中..."时才考虑重新测试连接
            if (modelManager && status !== "连接中..." && activeServer) {
                // 避免在连接测试过程中重复触发
                if (!isTestingConnection) {
                    testServerConnectionAsync(activeServer.address, activeServer.port)
                }
            }
        }
    }
    
    // 初始化时更新活跃服务器信息
    Component.onCompleted: {
        updateActiveServer()
        // 启动定时器，每10秒检查一次服务器状态
        statusTimer.start()
    }
    
    // 定时器，定期检查服务器状态
    Timer {
        id: statusTimer
        interval: 10000 // 10秒
        running: false
        repeat: true
        onTriggered: {
            if (modelManager && activeServer) {
                testServerConnectionAsync(activeServer.address, activeServer.port)
            }
        }
    }
    
    // 更新活跃服务器信息
    function updateActiveServer() {
        if (!modelManager) {
            activeServer = null
            isServerConnected = false
            isTestingConnection = false
            return
        }
        
        var servers = modelManager.servers
        for (var i = 0; i < servers.length; i++) {
            if (servers[i].isActive) {
                activeServer = servers[i]
                // 异步测试服务器连接状态
                testServerConnectionAsync(activeServer.address, activeServer.port)
                return
            }
        }
        // 如果没有活跃服务器，使用第一个服务器
        if (servers.length > 0) {
            activeServer = servers[0]
            // 异步测试服务器连接状态
            testServerConnectionAsync(activeServer.address, activeServer.port)
        } else {
            activeServer = null
            isServerConnected = false
            isTestingConnection = false
        }
    }
    

    
    // 异步测试服务器连接
    function testServerConnectionAsync(address, port) {
        // 设置测试中状态
        isTestingConnection = true
        isServerConnected = false
        statusMessage = "连接中..."
        
        // 使用模型管理器的异步测试方法
        if (modelManager) {
            modelManager.testServerConnectionAsync(address, port)
        } else {
            // 如果modelManager不存在，设置连接失败状态
            isTestingConnection = false
            isServerConnected = false
            statusMessage = "连接失败"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 标题
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.topMargin: 10

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Ollama管理器"
                    font.pointSize: 14
                    font.bold: true
                    color: "#ffffff"
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: appVersion ? "v" + appVersion : ""
                    font.pointSize: 10
                    color: "#999999"
                }
            }
        }

        // 导航按钮
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.topMargin: 10
            Layout.bottomMargin: 10

            // 概览分类
            Label {
                Layout.fillWidth: true
                text: "概览"
                font.pointSize: 10
                color: "#999999"
                Layout.leftMargin: 5
            }
            
            // 仪表盘
            Rectangle {
                id: dashboardBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: currentPage === "dashboard" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pageChanged("dashboard")
                    onEntered: {
                        if (currentPage !== "dashboard") {
                            dashboardBtn.color = "#2a2a2a"
                        }
                    }
                    onExited: {
                        if (currentPage !== "dashboard") {
                            dashboardBtn.color = "#1e1e1e"
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "仪表盘"
                    color: currentPage === "dashboard" ? "#ffffff" : "#cccccc"
                }
            }

            // 资源库分类
            Label {
                Layout.fillWidth: true
                text: "资源库"
                font.pointSize: 10
                color: "#999999"
                Layout.topMargin: 10
                Layout.leftMargin: 5
            }
            
            // 模型库
            Rectangle {
                id: modelLibraryBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: currentPage === "modelLibrary" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pageChanged("modelLibrary")
                    onEntered: {
                        if (currentPage !== "modelLibrary") {
                            modelLibraryBtn.color = "#2a2a2a"
                        }
                    }
                    onExited: {
                        if (currentPage !== "modelLibrary") {
                            modelLibraryBtn.color = "#1e1e1e"
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "模型库"
                    color: currentPage === "modelLibrary" ? "#ffffff" : "#cccccc"
                }
            }

            // 模型管理
            Rectangle {
                id: modelManagerBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: currentPage === "modelManager" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pageChanged("modelManager")
                    onEntered: {
                        if (currentPage !== "modelManager") {
                            modelManagerBtn.color = "#2a2a2a"
                        }
                    }
                    onExited: {
                        if (currentPage !== "modelManager") {
                            modelManagerBtn.color = "#1e1e1e"
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "已安装"
                    color: currentPage === "modelManager" ? "#ffffff" : "#cccccc"
                }
            }
            
            // 下载管理
            Rectangle {
                id: downloadManagerBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: currentPage === "downloadManager" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pageChanged("downloadManager")
                    onEntered: {
                        if (currentPage !== "downloadManager") {
                            downloadManagerBtn.color = "#2a2a2a"
                        }
                    }
                    onExited: {
                        if (currentPage !== "downloadManager") {
                            downloadManagerBtn.color = "#1e1e1e"
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "下载管理"
                    color: currentPage === "downloadManager" ? "#ffffff" : "#cccccc"
                }
            }

            // 服务器分类
            Label {
                Layout.fillWidth: true
                text: "服务器"
                font.pointSize: 10
                color: "#999999"
                Layout.topMargin: 10
                Layout.leftMargin: 5
            }
            
            // 服务器管理
            Rectangle {
                id: serverManagementBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: currentPage === "serverManagement" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pageChanged("serverManagement")
                    onEntered: {
                        if (currentPage !== "serverManagement") {
                            serverManagementBtn.color = "#2a2a2a"
                        }
                    }
                    onExited: {
                        if (currentPage !== "serverManagement") {
                            serverManagementBtn.color = "#1e1e1e"
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "服务器管理"
                    color: currentPage === "serverManagement" ? "#ffffff" : "#cccccc"
                }
            }

            // 助手分类
            Label {
                Layout.fillWidth: true
                text: "助手"
                font.pointSize: 10
                color: "#999999"
                Layout.topMargin: 10
                Layout.leftMargin: 5
            }
            
            // 添加助手
            Rectangle {
                id: addAssistantBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: currentPage === "addAssistant" ? "#2e4e3a" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pageChanged("addAssistant")
                    onEntered: {
                        if (currentPage !== "addAssistant") {
                            addAssistantBtn.color = "#2e4e3a"
                        }
                    }
                    onExited: {
                        if (currentPage !== "addAssistant") {
                            addAssistantBtn.color = "#1e1e1e"
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "+添加助手"
                    color: "#4ecdc4"
                }
            }
            
            // 默认助手
            Rectangle {
                id: defaultAssistantBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: currentPage === "defaultAssistant" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pageChanged("defaultAssistant")
                    onEntered: {
                        if (currentPage !== "defaultAssistant") {
                            defaultAssistantBtn.color = "#2a2a2a"
                        }
                    }
                    onExited: {
                        if (currentPage !== "defaultAssistant") {
                            defaultAssistantBtn.color = "#1e1e1e"
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "默认助手"
                    color: currentPage === "defaultAssistant" ? "#ffffff" : "#cccccc"
                }
            }

            // 设置分类
            Label {
                Layout.fillWidth: true
                text: "设置"
                font.pointSize: 10
                color: "#999999"
                Layout.topMargin: 10
                Layout.leftMargin: 5
            }
            
            // 设置
            Rectangle {
                id: settingsBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: currentPage === "settings" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pageChanged("settings")
                    onEntered: {
                        if (currentPage !== "settings") {
                            settingsBtn.color = "#2a2a2a"
                        }
                    }
                    onExited: {
                        if (currentPage !== "settings") {
                            settingsBtn.color = "#1e1e1e"
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "设置"
                    color: currentPage === "settings" ? "#ffffff" : "#cccccc"
                }
            }

            // 关于
            Rectangle {
                id: aboutBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: currentPage === "about" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pageChanged("about")
                    onEntered: {
                        if (currentPage !== "about") {
                            aboutBtn.color = "#2a2a2a"
                        }
                    }
                    onExited: {
                        if (currentPage !== "about") {
                            aboutBtn.color = "#1e1e1e"
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "关于"
                    color: currentPage === "about" ? "#ffffff" : "#cccccc"
                }
            }

            // 底部空间
            Item {
                Layout.fillHeight: true
            }
            
            // 服务器状态显示
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: "#1e1e1e"
                border {
                    width: 0
                }
                
                // 圆弧方框
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 10
                    color: "#252525"
                    radius: 8
                    border {
                        width: 1
                        color: "#333333"
                    }
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        
                        // 服务器信息行
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            
                            // 状态圆点
                            Item {
                                Layout.preferredWidth: 20
                                Layout.fillHeight: true
                                
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: isTestingConnection ? "#feca57" : (isServerConnected ? "#00FF00" : "#ff4757")
                                }
                            }
                            
                            // 服务器信息
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2
                                
                                Label {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignLeft
                                    text: activeServer ? activeServer.name : "无服务器"
                                    font.pointSize: 12
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignLeft
                                    text: activeServer ? activeServer.address : ""
                                    font.pointSize: 10
                                    color: "#999999"
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        
                        // 状态描述行
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: "#333333"
                        }
                        
                        Label {
                            Layout.fillWidth: true
                            text: statusMessage
                            font.pointSize: 11
                            color: "#4ecdc4"
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
    
    // 监听currentPage变化，直接更新每个按钮的颜色
    onCurrentPageChanged: {
        dashboardBtn.color = currentPage === "dashboard" ? "#333333" : "#1e1e1e"
        modelLibraryBtn.color = currentPage === "modelLibrary" ? "#333333" : "#1e1e1e"
        modelManagerBtn.color = currentPage === "modelManager" ? "#333333" : "#1e1e1e"
        downloadManagerBtn.color = currentPage === "downloadManager" ? "#333333" : "#1e1e1e"
        serverManagementBtn.color = currentPage === "serverManagement" ? "#333333" : "#1e1e1e"
        addAssistantBtn.color = currentPage === "addAssistant" ? "#2e4e3a" : "#1e1e1e"
        defaultAssistantBtn.color = currentPage === "defaultAssistant" ? "#333333" : "#1e1e1e"
        settingsBtn.color = currentPage === "settings" ? "#333333" : "#1e1e1e"
        aboutBtn.color = currentPage === "about" ? "#333333" : "#1e1e1e"
    }
}