import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: settingsPage
    property string currentPage: "modelManager"
    width: parent.width
    height: parent.height
    color: "#121212"
    
    // 存储服务器数据的数组
    property var serverData: []
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 头部
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 10

            Label {
                text: "服务器管理"
                font.pointSize: 16
                font.bold: true
                color: "#ffffff"
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "新建服务器"
                onClicked: {
                    newServerDialog.visible = true
                }
                background: Rectangle {
                    color: "#4ecdc4"
                    radius: 8
                    border {
                        width: 1
                        color: "#5eddd6"
                    }
                }
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // 服务器列表
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1e1e1e"
            radius: 12
            border {
                width: 1
                color: "#333333"
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 表头
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: "#252525"
                    radius: 8
                    border {
                        width: 1
                        color: "#333333"
                    }

                    RowLayout {
                        id: headerLayout
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 0

                        // 服务器名称列
                        Item {
                            Layout.preferredWidth: 200
                            Layout.fillHeight: true
                            Label {
                                anchors.centerIn: parent
                                text: "服务器名称"
                                font.bold: true
                                color: "#ffffff"
                                font.pointSize: 12
                            }
                        }

                        // 分隔符1
                        Item {
                            Layout.preferredWidth: 15
                            Layout.fillHeight: true
                            Rectangle {
                                anchors.centerIn: parent
                                width: 1
                                height: parent.height
                                color: "#444444"
                            }
                        }

                        // 服务器地址列
                        Item {
                            Layout.preferredWidth: 200
                            Layout.fillHeight: true
                            Label {
                                anchors.centerIn: parent
                                text: "服务器地址"
                                font.bold: true
                                color: "#ffffff"
                                font.pointSize: 12
                            }
                        }

                        // 分隔符2
                        Item {
                            Layout.preferredWidth: 15
                            Layout.fillHeight: true
                            Rectangle {
                                anchors.centerIn: parent
                                width: 1
                                height: parent.height
                                color: "#444444"
                            }
                        }

                        // 端口列
                        Item {
                            Layout.preferredWidth: 100
                            Layout.fillHeight: true
                            Label {
                                anchors.centerIn: parent
                                text: "端口"
                                font.bold: true
                                color: "#ffffff"
                                font.pointSize: 12
                            }
                        }

                        // 分隔符3
                        Item {
                            Layout.preferredWidth: 15
                            Layout.fillHeight: true
                            Rectangle {
                                anchors.centerIn: parent
                                width: 1
                                height: parent.height
                                color: "#444444"
                            }
                        }

                        // 状态列
                        Item {
                            Layout.preferredWidth: 100
                            Layout.fillHeight: true
                            Label {
                                anchors.centerIn: parent
                                text: "状态"
                                font.bold: true
                                color: "#ffffff"
                                font.pointSize: 12
                            }
                        }

                        // 分隔符4
                        Item {
                            Layout.preferredWidth: 15
                            Layout.fillHeight: true
                            Rectangle {
                                anchors.centerIn: parent
                                width: 1
                                height: parent.height
                                color: "#444444"
                            }
                        }

                        // 操作列
                        Item {
                            Layout.preferredWidth: 190
                            Layout.fillHeight: true
                            Label {
                                anchors.centerIn: parent
                                text: "操作"
                                font.bold: true
                                color: "#ffffff"
                                font.pointSize: 12
                            }
                        }
                    }
                }

                // 服务器列表
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0
                    model: modelManager.servers
                    clip: true
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOn
                    }

                    delegate: Rectangle {
                        width: parent.width
                        height: 50
                        color: index % 2 === 0 ? "#1e1e1e" : "#252525"
                        border {
                            width: 1
                            color: "#333333"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            spacing: 0

                            // 服务器名称
                            Item {
                                Layout.preferredWidth: 200
                                Layout.fillHeight: true
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData && modelData.hasOwnProperty("name") ? modelData.name : ""
                                    color: "#ffffff"
                                    font.pointSize: 12
                                }
                            }

                            // 分隔符1
                            Item {
                                Layout.preferredWidth: 15
                                Layout.fillHeight: true
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 1
                                    height: parent.height
                                    color: "#444444"
                                }
                            }

                            // 服务器地址
                            Item {
                                Layout.preferredWidth: 200
                                Layout.fillHeight: true
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData && modelData.hasOwnProperty("address") ? modelData.address : ""
                                    color: "#ffffff"
                                    font.pointSize: 12
                                }
                            }

                            // 分隔符2
                            Item {
                                Layout.preferredWidth: 15
                                Layout.fillHeight: true
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 1
                                    height: parent.height
                                    color: "#444444"
                                }
                            }

                            // 端口
                            Item {
                                Layout.preferredWidth: 100
                                Layout.fillHeight: true
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData && modelData.hasOwnProperty("port") ? modelData.port : ""
                                    color: "#ffffff"
                                    font.pointSize: 12
                                }
                            }

                            // 分隔符3
                            Item {
                                Layout.preferredWidth: 15
                                Layout.fillHeight: true
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 1
                                    height: parent.height
                                    color: "#444444"
                                }
                            }

                            // 状态
                            Item {
                                Layout.preferredWidth: 100
                                Layout.fillHeight: true
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData && modelData.hasOwnProperty("isActive") ? (modelData.isActive ? "活跃" : "未使用") : "未使用"
                                    color: modelData && modelData.hasOwnProperty("isActive") && modelData.isActive ? "#4ecdc4" : "#999999"
                                    font.pointSize: 12
                                }
                            }

                            // 分隔符4
                            Item {
                                Layout.preferredWidth: 15
                                Layout.fillHeight: true
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 1
                                    height: parent.height
                                    color: "#444444"
                                }
                            }

                            // 操作
                            Item {
                                Layout.preferredWidth: 190
                                Layout.fillHeight: true
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Button {
                                        text: "设为活跃"
                                        width: 80
                                        height: 28
                                        onClicked: {
                                            modelManager.setActiveServer(index)
                                        }
                                        background: Rectangle {
                                            color: "#4ecdc4"
                                            radius: 6
                                            border {
                                                width: 1
                                                color: "#5eddd6"
                                            }
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            color: "#ffffff"
                                            font.pointSize: 10
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    Button {
                                        text: "编辑"
                                        width: 50
                                        height: 28
                                        onClicked: {
                                            editServerDialog.serverIndex = index
                                            editServerDialog.serverData = modelData
                                            editServerDialog.visible = true
                                        }
                                        background: Rectangle {
                                            color: "#3498db"
                                            radius: 6
                                            border {
                                                width: 1
                                                color: "#44a8eb"
                                            }
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            color: "#ffffff"
                                            font.pointSize: 10
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    Button {
                                        text: "删除"
                                        width: 50
                                        height: 28
                                        onClicked: {
                                            modelManager.removeServer(index)
                                        }
                                        background: Rectangle {
                                            color: "#ff4757"
                                            radius: 6
                                            border {
                                                width: 1
                                                color: "#ff6b81"
                                            }
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            color: "#ffffff"
                                            font.pointSize: 10
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
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
    
    // 新建服务器对话框
    Rectangle {
        id: newServerDialog
        visible: false
        anchors.centerIn: parent
        width: 500
        height: 300
        color: "#1e1e1e"
        radius: 12
        border {
            width: 1
            color: "#333333"
        }
        z: 100

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Label {
                text: "新建服务器"
                font.pointSize: 16
                font.bold: true
                color: "#ffffff"
            }

            // 服务器名称
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "服务器名称:"
                    color: "#ffffff"
                    Layout.preferredWidth: 100
                }

                TextField {
                    id: newServerName
                    placeholderText: "输入服务器名称"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: "#2a2a2a"
                        radius: 8
                        border {
                            width: 1
                            color: "#333333"
                        }
                    }
                    color: "#ffffff"
                    placeholderTextColor: "#999999"
                }
            }

            // 服务器地址
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "服务器地址:"
                    color: "#ffffff"
                    Layout.preferredWidth: 100
                }

                TextField {
                    id: newServerAddress
                    placeholderText: "localhost"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: "#2a2a2a"
                        radius: 8
                        border {
                            width: 1
                            color: "#333333"
                        }
                    }
                    color: "#ffffff"
                    placeholderTextColor: "#999999"
                }
            }

            // 端口
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "端口:"
                    color: "#ffffff"
                    Layout.preferredWidth: 100
                }

                TextField {
                    id: newServerPort
                    placeholderText: "11434"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: "#2a2a2a"
                        radius: 8
                        border {
                            width: 1
                            color: "#333333"
                        }
                    }
                    color: "#ffffff"
                    placeholderTextColor: "#999999"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "取消"
                    onClicked: {
                        newServerDialog.visible = false
                        newServerName.text = ""
                        newServerAddress.text = ""
                        newServerPort.text = ""
                    }
                    background: Rectangle {
                        color: "#2a2a2a"
                        radius: 8
                        border {
                            width: 1
                            color: "#333333"
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "保存"
                    onClicked: {
                        if (newServerName.text && newServerAddress.text && newServerPort.text) {
                            // 添加新服务器
                            modelManager.addServer(newServerName.text, newServerAddress.text, newServerPort.text)
                            
                            // 清空输入
                            newServerName.text = ""
                            newServerAddress.text = ""
                            newServerPort.text = ""
                            newServerDialog.visible = false
                        }
                    }
                    background: Rectangle {
                        color: "#4ecdc4"
                        radius: 8
                        border {
                            width: 1
                            color: "#5eddd6"
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
    
    // 编辑服务器对话框
    Rectangle {
        id: editServerDialog
        visible: false
        anchors.centerIn: parent
        width: 500
        height: 300
        color: "#1e1e1e"
        radius: 12
        border {
            width: 1
            color: "#333333"
        }
        z: 100
        
        // 存储要编辑的服务器索引和数据
        property int serverIndex: -1
        property var serverData: null

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Label {
                text: "编辑服务器"
                font.pointSize: 16
                font.bold: true
                color: "#ffffff"
            }

            // 服务器名称
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "服务器名称:"
                    color: "#ffffff"
                    Layout.preferredWidth: 100
                }

                TextField {
                    id: editServerName
                    placeholderText: "输入服务器名称"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: "#2a2a2a"
                        radius: 8
                        border {
                            width: 1
                            color: "#333333"
                        }
                    }
                    color: "#ffffff"
                    placeholderTextColor: "#999999"
                }
            }

            // 服务器地址
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "服务器地址:"
                    color: "#ffffff"
                    Layout.preferredWidth: 100
                }

                TextField {
                    id: editServerAddress
                    placeholderText: "localhost"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: "#2a2a2a"
                        radius: 8
                        border {
                            width: 1
                            color: "#333333"
                        }
                    }
                    color: "#ffffff"
                    placeholderTextColor: "#999999"
                }
            }

            // 端口
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "端口:"
                    color: "#ffffff"
                    Layout.preferredWidth: 100
                }

                TextField {
                    id: editServerPort
                    placeholderText: "11434"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: "#2a2a2a"
                        radius: 8
                        border {
                            width: 1
                            color: "#333333"
                        }
                    }
                    color: "#ffffff"
                    placeholderTextColor: "#999999"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "取消"
                    onClicked: {
                        editServerDialog.visible = false
                        editServerName.text = ""
                        editServerAddress.text = ""
                        editServerPort.text = ""
                    }
                    background: Rectangle {
                        color: "#2a2a2a"
                        radius: 8
                        border {
                            width: 1
                            color: "#333333"
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "保存"
                    onClicked: {
                        if (editServerName.text && editServerAddress.text && editServerPort.text) {
                            // 更新服务器信息
                            modelManager.updateServer(editServerDialog.serverIndex, editServerName.text, editServerAddress.text, editServerPort.text)
                            
                            // 清空输入
                            editServerName.text = ""
                            editServerAddress.text = ""
                            editServerPort.text = ""
                            editServerDialog.visible = false
                        }
                    }
                    background: Rectangle {
                        color: "#4ecdc4"
                        radius: 8
                        border {
                            width: 1
                            color: "#5eddd6"
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        
        // 当对话框可见时，填充表单数据
        onVisibleChanged: {
            if (visible && serverData) {
                editServerName.text = serverData.name || ""
                editServerAddress.text = serverData.address || ""
                editServerPort.text = serverData.port || ""
            }
        }
    }
}