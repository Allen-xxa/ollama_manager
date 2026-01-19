import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 220
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

        // 拉取进度条
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#2a2a2a"
            radius: 8
            border {
                width: 1
                color: "#333333"
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Label {
                    text: "进度:"
                    color: "#ffffff"
                    Layout.preferredWidth: 50
                }

                Rectangle {
                    id: progressBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 12
                    color: "#333333"
                    radius: 6

                    Rectangle {
                        id: progressFill
                        width: 0
                        height: parent.height
                        color: "#4ecdc4"
                        radius: 6
                    }
                }

                Label {
                    id: progressText
                    text: "0%"
                    color: "#ffffff"
                    Layout.preferredWidth: 50
                }
            }
        }

        // 下载速度和预估时间
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            Label {
                id: downloadSpeed
                text: "下载速度: 0 MB/s"
                color: "#999999"
            }

            Label {
                id: estimatedTime
                text: "预估时间: 0s"
                color: "#999999"
            }
        }
    }
}