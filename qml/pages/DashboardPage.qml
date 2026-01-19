import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: dashboardPage
    property string currentPage: "modelManager"
    width: parent.width
    height: parent.height
    color: "#121212"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            text: "仪表盘"
            font.pointSize: 16
            font.bold: true
            color: "#ffffff"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1e1e1e"
            radius: 12
            border {
                width: 1
                color: "#333333"
            }

            Label {
                anchors.centerIn: parent
                text: "仪表盘功能开发中..."
                color: "#cccccc"
            }
        }
    }
}