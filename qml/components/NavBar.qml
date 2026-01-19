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
    z: 0

    property string currentPage: "modelManager"
    signal pageChanged(string page)
    
    // 存储活跃服务器信息
    property var activeServer: null
    property bool isServerConnected: false
    property bool isTestingConnection: false
    
    // 连接到modelManager获取活跃服务器信息
    Connections {
        target: modelManager
        function onServersUpdated() {
            updateActiveServer()
        }
    }
    
    // 初始化时更新活跃服务器信息
    Component.onCompleted: {
        updateActiveServer()
    }
    
    // 更新活跃服务器信息
    function updateActiveServer() {
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
        // 先假设连接失败，避免UI卡顿
        isServerConnected = false
        
        // 使用更可靠的方式处理异步操作
        // 立即开始测试，不使用setTimeout
        try {
            // 这里我们使用同步方法，但在实际应用中，
            // 我们应该使用信号来通知测试结果
            var connected = modelManager.testServerConnection(address, port)
            isServerConnected = connected
        } catch (e) {
            console.log("Error testing server connection:", e)
            isServerConnected = false
        } finally {
            // 无论如何都要重置测试状态
            isTestingConnection = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 标题
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#252525"
            border {
                width: 1
                color: "#333333"
            }

            Label {
                anchors.centerIn: parent
                text: "Ollama 管理"
                font.pointSize: 14
                font.bold: true
                color: "#ffffff"
            }
        }

        // 导航按钮
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // 仪表盘
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: currentPage === "dashboard" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: pageChanged("dashboard")
                }

                Label {
                    anchors.centerIn: parent
                    text: "仪表盘"
                    color: currentPage === "dashboard" ? "#ffffff" : "#cccccc"
                }
            }

            // 模型库
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: currentPage === "modelLibrary" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: pageChanged("modelLibrary")
                }

                Label {
                    anchors.centerIn: parent
                    text: "模型库"
                    color: currentPage === "modelLibrary" ? "#ffffff" : "#cccccc"
                }
            }

            // 模型管理
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: currentPage === "modelManager" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: pageChanged("modelManager")
                }

                Label {
                    anchors.centerIn: parent
                    text: "模型管理"
                    color: currentPage === "modelManager" ? "#ffffff" : "#cccccc"
                }
            }

            // 服务器管理
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: currentPage === "serverManagement" ? "#333333" : "#1e1e1e"
                border {
                    width: 1
                    color: "#333333"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: pageChanged("serverManagement")
                }

                Label {
                    anchors.centerIn: parent
                    text: "服务器管理"
                    color: currentPage === "serverManagement" ? "#ffffff" : "#cccccc"
                }
            }

            // 底部空间
            Item {
                Layout.fillHeight: true
            }
            
            // 服务器状态显示
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
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
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
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
                                color: isTestingConnection ? "#feca57" : (isServerConnected ? "#4ecdc4" : "#ff4757")
                            }
                        }
                        
                        // 服务器信息
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 5
                            
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
                }
            }
        }
    }
}