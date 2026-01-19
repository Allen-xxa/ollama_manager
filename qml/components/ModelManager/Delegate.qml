import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../utils/Utils.js" as Utils

Item {
    id: delegateRoot
    signal deleteRequested(string modelName)

    width: modelList.colWidth1 + 15 + modelList.colWidth4 + 15 + modelList.colWidth2 + 15 + modelList.colWidth3 + 15 + modelList.colWidth5 + 15 + modelList.colWidth6
    height: 45

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 0

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#333333"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = "#2a2a2a"
            onExited: parent.color = "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 0

            Item {
                Layout.preferredWidth: modelList.colWidth1
                Layout.fillHeight: true
                Label {
                    anchors.fill: parent
                    text: name
                    font.bold: true
                    color: "#ffffff"
                    font.pointSize: 11
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    leftPadding: 5
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

            Item {
                Layout.preferredWidth: modelList.colWidth4
                Layout.fillHeight: true
                Label {
                    anchors.fill: parent
                    text: Utils.parseModelFamily(name)
                    color: "#cccccc"
                    font.pointSize: 11
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
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

            Item {
                Layout.preferredWidth: modelList.colWidth2
                Layout.fillHeight: true
                Label {
                    anchors.fill: parent
                    text: Utils.parseParamSize(name)
                    color: "#cccccc"
                    font.pointSize: 11
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
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

            Item {
                Layout.preferredWidth: modelList.colWidth3
                Layout.fillHeight: true
                Label {
                    anchors.fill: parent
                    text: Utils.formatFileSize(size)
                    color: "#999999"
                    font.pointSize: 11
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
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

            Item {
                Layout.preferredWidth: modelList.colWidth5
                Layout.fillHeight: true
                Label {
                    anchors.fill: parent
                    text: Utils.parseQuantization(name)
                    color: "#cccccc"
                    font.pointSize: 11
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
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
            }

            Item {
                Layout.fillWidth: true
            }

            Item {
                Layout.preferredWidth: modelList.colWidth6
                Layout.fillHeight: true
                RowLayout {
                    anchors.fill: parent
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 26
                        Layout.alignment: Qt.AlignVCenter
                        color: "#4ecdc4"
                        radius: 4
                        border {
                            width: 1
                            color: "#5eddd6"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                modelManager.pullModel(name)
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: "更新"
                            color: "white"
                            font.pointSize: 10
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 26
                        Layout.alignment: Qt.AlignVCenter
                        color: "#ff6b6b"
                        radius: 4
                        border {
                            width: 1
                            color: "#ff8787"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                delegateRoot.deleteRequested(name)
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: "删除"
                            color: "white"
                            font.pointSize: 10
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}