import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    Layout.fillWidth: true
    spacing: 10

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
}