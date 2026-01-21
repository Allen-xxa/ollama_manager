import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: addAssistantPage
    property string currentPage: "addAssistant"
    width: parent.width
    height: parent.height
    color: "#121212"

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "添加助手"
            font.pointSize: 24
            font.bold: true
            color: "#ffffff"
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 200
            color: "#1e1e1e"
            radius: 12
            border {
                width: 1
                color: "#333333"
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 15

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "开发中"
                    font.pointSize: 18
                    color: "#4ecdc4"
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "敬请期待..."
                    font.pointSize: 14
                    color: "#999999"
                }
            }
        }
    }
}