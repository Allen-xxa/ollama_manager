import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: modelManagerPage
    property string currentPage: "modelManager"
    property string deleteModelName: ""
    property bool showDeleteDialog: false
    width: parent.width
    height: parent.height
    color: "#121212"

    function showDeleteConfirmation(modelName) {
        deleteModelName = modelName
        showDeleteDialog = true
    }

    function closeDeleteDialog() {
        showDeleteDialog = false
        deleteModelName = ""
    }

    function confirmDelete() {
        modelManager.deleteModel(deleteModelName)
        closeDeleteDialog()
    }
    
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
                text: "已安装"
                font.pointSize: 20
                font.bold: true
                color: "#ffffff"
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "刷新"
                onClicked: modelManager.getModels()
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
        }

        // 模型列表
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 300
            color: "#1e1e1e"
            radius: 8
            border {
                width: 1
                color: "#333333"
            }

            // 横向滚动容器
            Flickable {
                id: horizontalFlickable
                anchors.fill: parent
                contentWidth: width // 使用容器宽度，不需要横向滚动
                contentHeight: height
                clip: true
                // 移除横向滚动条

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 表头
                    Rectangle {
                        id: header
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

                            // 模型名称列
                            Item {
                                Layout.preferredWidth: modelList.colWidth1
                                Layout.fillHeight: true
                                Label {
                                    anchors.centerIn: parent
                                    text: "模型名称"
                                    font.bold: true
                                    color: "#ffffff"
                                    font.pointSize: 12
                                }
                            }

                            // 模型系列列
                            Item {
                                Layout.preferredWidth: modelList.colWidth4
                                Layout.fillHeight: true
                                Label {
                                    anchors.centerIn: parent
                                    text: "模型系列"
                                    font.bold: true
                                    color: "#ffffff"
                                    font.pointSize: 12
                                }
                            }

                            // 参数量列
                            Item {
                                Layout.preferredWidth: modelList.colWidth2
                                Layout.fillHeight: true
                                Label {
                                    anchors.centerIn: parent
                                    text: "参数量"
                                    font.bold: true
                                    color: "#ffffff"
                                    font.pointSize: 12
                                }
                            }

                            // 文件大小列
                            Item {
                                Layout.preferredWidth: modelList.colWidth3
                                Layout.fillHeight: true
                                Label {
                                    anchors.centerIn: parent
                                    text: "文件大小"
                                    font.bold: true
                                    color: "#ffffff"
                                    font.pointSize: 12
                                }
                            }

                            // 量化列
                            Item {
                                Layout.preferredWidth: modelList.colWidth5
                                Layout.fillHeight: true
                                Label {
                                    anchors.centerIn: parent
                                    text: "量化"
                                    font.bold: true
                                    color: "#ffffff"
                                    font.pointSize: 12
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            // 操作列
                            Item {
                                Layout.preferredWidth: modelList.colWidth6
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

                    // 模型列表垂直滚动区域
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width // 使用容器宽度，不需要横向滚动
                        contentHeight: modelList.contentHeight
                        clip: true
                        flickableDirection: Flickable.VerticalFlick
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded // 只有在需要时才显示滚动条
                        }

                        ListView {
                            id: modelList
                            // 按比例计算列宽
                            property real totalWidth: parent.width - 40 // 减去左右边距
                            property real colWidth1: totalWidth * 0.4 // 模型名称列占40%
                            property real colWidth2: totalWidth * 0.1 // 参数量列占10%
                            property real colWidth3: totalWidth * 0.1 // 文件大小列占10%
                            property real colWidth4: totalWidth * 0.15 // 模型系列列占15%
                            property real colWidth5: totalWidth * 0.1 // 量化列占10%
                            property real colWidth6: totalWidth * 0.15 // 操作列占15%
                            width: parent.width
                            height: parent.height
                            spacing: 0
                            model: modelData
                            clip: true
                            // 计算总列宽
                            property real totalColumnWidth: colWidth1 + colWidth2 + colWidth3 + colWidth4 + colWidth5 + colWidth6
                            contentWidth: totalColumnWidth

                            delegate: Loader {
                                source: "Delegate.qml"
                                onLoaded: {
                                    item.deleteRequested.connect(function(modelName) {
                                        modelManagerPage.showDeleteConfirmation(modelName)
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }

        // 操作面板
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
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

                Label {
                    text: "模型操作"
                    font.bold: true
                    color: "#ffffff"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    TextField {
                        id: modelInput
                        placeholderText: "模型名称 (例如: llama3:8b)"
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

                    Button {
                        text: "拉取模型"
                        onClicked: {
                            if (modelInput.text) {
                                modelManager.pullModel(modelInput.text)
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
    }

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
                    text: "删除模型"
                    font.pointSize: 16
                    font.bold: true
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                }

                Label {
                    Layout.fillWidth: true
                    text: "正在删除 " + deleteModelName
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

    // 存储信号连接
    property var modelUpdatedConnection
    // 模型数据
    ListModel {
        id: modelData
    }

    // 连接信号
    Component.onCompleted: {
        // 连接模型更新信号
        modelUpdatedConnection = modelManager.modelsUpdated.connect(function(models) {
            // 清空现有模型数据
            if (modelData) {
                modelData.clear()
                
                // 添加新模型数据
                for (var i = 0; i < models.length; i++) {
                    var model = models[i]
                    modelData.append({
                        name: model.name,
                        size: model.size || 0
                    })
                }
            }
        })
        
        // 主动获取模型列表
        modelManager.getModels()
    }
    
    // 断开信号连接
    Component.onDestruction: {
        if (modelUpdatedConnection) {
            modelUpdatedConnection.disconnect()
        }
    }
}