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
                text: "模型管理"
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
                            MouseArea {
                                id: mouseArea1
                                anchors.fill: parent
                                cursorShape: Qt.SplitHCursor
                                property real startX: 0
                                property real startWidth: 0
                                onPressed: function(mouse) {
                                    startX = mapToItem(modelList, mouse.x, 0).x
                                    startWidth = modelList.colWidth1
                                }
                                onPositionChanged: function(mouse) {
                                    if (pressed) {
                                        var currentX = mapToItem(modelList, mouse.x, 0).x
                                        var newWidth = startWidth + (currentX - startX)
                                        if (newWidth > 100) {
                                            modelList.colWidth1 = newWidth
                                        }
                                    }
                                }
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
                            MouseArea {
                                id: mouseArea2
                                anchors.fill: parent
                                cursorShape: Qt.SplitHCursor
                                property real startX: 0
                                property real startWidth: 0
                                onPressed: function(mouse) {
                                    startX = mapToItem(modelList, mouse.x, 0).x
                                    startWidth = modelList.colWidth4
                                }
                                onPositionChanged: function(mouse) {
                                    if (pressed) {
                                        var currentX = mapToItem(modelList, mouse.x, 0).x
                                        var newWidth = startWidth + (currentX - startX)
                                        if (newWidth > 80) {
                                            modelList.colWidth4 = newWidth
                                        }
                                    }
                                }
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
                            MouseArea {
                                id: mouseArea3
                                anchors.fill: parent
                                cursorShape: Qt.SplitHCursor
                                property real startX: 0
                                property real startWidth: 0
                                onPressed: function(mouse) {
                                    startX = mapToItem(modelList, mouse.x, 0).x
                                    startWidth = modelList.colWidth2
                                }
                                onPositionChanged: function(mouse) {
                                    if (pressed) {
                                        var currentX = mapToItem(modelList, mouse.x, 0).x
                                        var newWidth = startWidth + (currentX - startX)
                                        if (newWidth > 50) {
                                            modelList.colWidth2 = newWidth
                                        }
                                    }
                                }
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
                            MouseArea {
                                id: mouseArea4
                                anchors.fill: parent
                                cursorShape: Qt.SplitHCursor
                                property real startX: 0
                                property real startWidth: 0
                                onPressed: function(mouse) {
                                    startX = mapToItem(modelList, mouse.x, 0).x
                                    startWidth = modelList.colWidth3
                                }
                                onPositionChanged: function(mouse) {
                                    if (pressed) {
                                        var currentX = mapToItem(modelList, mouse.x, 0).x
                                        var newWidth = startWidth + (currentX - startX)
                                        if (newWidth > 80) {
                                            modelList.colWidth3 = newWidth
                                        }
                                    }
                                }
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

                        // 分隔符5
                        Item {
                            Layout.preferredWidth: 15
                            Layout.fillHeight: true
                            Rectangle {
                                anchors.centerIn: parent
                                width: 1
                                height: parent.height
                                color: "#444444"
                            }
                            MouseArea {
                                id: mouseArea5
                                anchors.fill: parent
                                cursorShape: Qt.SplitHCursor
                                property real startX: 0
                                property real startWidth: 0
                                onPressed: function(mouse) {
                                    startX = mapToItem(modelList, mouse.x, 0).x
                                    startWidth = modelList.colWidth5
                                }
                                onPositionChanged: function(mouse) {
                                    if (pressed) {
                                        var currentX = mapToItem(modelList, mouse.x, 0).x
                                        var newWidth = startWidth + (currentX - startX)
                                        if (newWidth > 60) {
                                            modelList.colWidth5 = newWidth
                                        }
                                    }
                                }
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

                // 模型列表
                ListView {
                    id: modelList
                    property real colWidth1: 500
                    property real colWidth2: 80
                    property real colWidth3: 100
                    property real colWidth4: 150
                    property real colWidth5: 80
                    property real colWidth6: 140
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0
                    model: ListModel {
                        id: modelData
                    }
                    clip: true
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOn
                    }
                    ScrollBar.horizontal: ScrollBar {
                        policy: ScrollBar.AlwaysOn
                    }

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