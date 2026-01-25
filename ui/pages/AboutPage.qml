import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: aboutPage
    property string currentPage: "about"
    width: parent.width
    height: parent.height
    color: "#121212"
    
    property var updateInfo: null
    property bool isChecking: false
    property bool isDownloading: false
    property bool isInstalling: false
    property string downloadProgress: "0%"
    property string downloadSpeed: "0 B/s"
    property string downloadEta: "计算中..."
    property string statusMessage: "准备就绪"
    property string errorMessage: ""
    property bool showUpdateDialog: false
    property string updateVersion: ""
    property string updateReleaseNotes: ""
    
    // 更新设置属性
    property bool autoUpdateEnabled: false
    
    // 初始化
    Component.onCompleted: {
        // 加载更新设置
        loadUpdateSettings()
    }
    
    // 加载更新设置
    function loadUpdateSettings() {
        if (updateManager) {
            autoUpdateEnabled = updateManager.autoDownload && updateManager.autoInstall
        }
    }
    
    // 切换自动更新状态
    function toggleAutoUpdate() {
        if (updateManager && modelManager) {
            autoUpdateEnabled = !autoUpdateEnabled
            
            // 获取当前设置
            var settings = modelManager.settings || {}
            // 更新更新设置
            settings.update = {
                'update_server': updateManager.updateServer,
                'check_interval': updateManager.checkInterval,
                'auto_download': autoUpdateEnabled,
                'auto_install': autoUpdateEnabled,
                'backup_enabled': updateManager.backupEnabled,
                'developer_mode': updateManager.developerMode
            }
            // 保存设置
            modelManager.saveAllSettings(settings)
            // 重新加载更新管理器配置
            updateManager.reloadConfig()
            
            // 显示提示
            showToast(autoUpdateEnabled ? "自动更新已开启" : "自动更新已关闭")
        }
    }
    
    Connections {
        target: updateManager
        
        function onUpdateAvailable(info) {
            // console.log("📋 收到更新信息，类型:", typeof info)
            // console.log("📋 info对象:", info)
            
            // 尝试获取对象的所有键
            try {
                var keys = Object.keys(info)
                // console.log("📋 info对象的键:", keys)
            } catch (e) {
                // console.log("📋 无法获取对象键:", e)
            }
            
            // 尝试直接访问属性
            // console.log("📋 尝试访问version属性:", info.version)
            // console.log("📋 尝试访问release_notes属性:", info.release_notes)
            
            // 提取版本和更新内容
            updateVersion = info.version || ""
            updateReleaseNotes = info.release_notes || ""
            
            updateInfo = info
            statusMessage = "发现新版本: " + updateVersion
            showUpdateDialog = true
            // console.log("📋 提取的版本号:", updateVersion)
            // console.log("📋 提取的更新内容:", updateReleaseNotes)
        }
        
        function onUpdateNotAvailable() {
        statusMessage = "当前已是最新版本"
        isChecking = false
        showUpdateDialog = false
        showToast("当前已是最新版本")
    }
    
    function onUpdateDownloadProgress(progress, speed, eta) {
        downloadProgress = progress.toFixed(1) + "%"
        downloadSpeed = speed
        downloadEta = eta
        statusMessage = "正在下载: " + downloadProgress
    }
    
    function onUpdateDownloadComplete(filePath) {
        statusMessage = "下载完成，准备启动更新程序"
        isDownloading = false
        console.log("📥 下载完成")
        console.log("📥 下载文件路径:", filePath)
        
        if (updateManager) {
            console.log("🚀 启动更新程序")
            updateManager.launchUpdater()
        }
    }
    
    function onUpdateDownloadFailed(error) {
        errorMessage = error
        statusMessage = "下载失败: " + error
        isDownloading = false
        showToast("下载失败: " + error)
    }
    
    function onUpdateInstallProgress(progress) {
        statusMessage = "正在安装: " + (progress * 100).toFixed(0) + "%"
    }
    
    function onUpdateInstallComplete() {
        statusMessage = "安装完成，请重启应用"
        isInstalling = false
        showUpdateDialog = false
        showToast("安装完成，请重启应用")
    }
    
    function onUpdateInstallFailed(error) {
        errorMessage = error
        statusMessage = "安装失败: " + error
        isInstalling = false
        showToast("安装失败: " + error)
    }
    
    function onUpdateCheckFailed(error) {
        errorMessage = error
        statusMessage = "检查更新失败: " + error
        isChecking = false
        showUpdateDialog = false
        showToast("检查更新失败: " + error)
    }
        
        function onUpdateCancelled() {
            statusMessage = "已取消"
            isDownloading = false
        }
    }

    Rectangle {
        id: updateDialog
        anchors.centerIn: parent
        width: 500
        height: 400
        color: "#1e1e1e"
        radius: 12
        border {
            width: 1
            color: "#333333"
        }
        visible: showUpdateDialog
        z: 100
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            Label {
                text: "发现新版本"
                font.pointSize: 16
                font.bold: true
                color: "#ffffff"
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#333333"
            }
            
            Label {
                text: "新版本: v" + (updateVersion || "")
                font.pointSize: 14
                font.bold: true
                color: "#3b82f6"
            }
            
            Label {
                text: "更新内容:"
                font.pointSize: 12
                font.bold: true
                color: "#ffffff"
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                TextArea {
                    text: updateReleaseNotes || ""
                    color: "#9ca3af"
                    font.pointSize: 11
                    wrapMode: Text.Wrap
                    readOnly: true
                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#333333"
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Button {
                    text: "取消"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 36
                    enabled: !isDownloading && !isInstalling
                    background: Rectangle {
                        color: parent.enabled ? (parent.hovered ? "#444444" : "#333333") : "#252525"
                        radius: 6
                        border {
                            width: 1
                            color: "#555555"
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "#ffffff" : "#666666"
                        font.pointSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        showUpdateDialog = false
                        updateInfo = null
                        updateVersion = ""
                        updateReleaseNotes = ""
                    }
                }
                
                Button {
                    text: isDownloading ? "下载中..." : (isInstalling ? "安装中..." : "立即更新")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    enabled: !isDownloading && !isInstalling
                    background: Rectangle {
                        color: parent.enabled ? (parent.hovered ? "#2563eb" : "#3b82f6") : "#252525"
                        radius: 6
                        border {
                            width: 1
                            color: parent.enabled ? "#60a5fa" : "#444444"
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "#ffffff" : "#666666"
                        font.pointSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (updateManager) {
                            var developerMode = updateManager.getDeveloperMode()
                            console.log("📋 开发者模式状态:", developerMode)
                            
                            if (developerMode) {
                                console.log("🚀 开发者模式：直接启动更新程序")
                                statusMessage = "正在启动更新程序..."
                                updateManager.launchUpdater()
                            } else {
                                console.log("📥 GitHub/远程模式：先下载更新包")
                                isDownloading = true
                                statusMessage = "正在下载更新包..."
                                updateManager.downloadUpdate()
                            }
                        }
                    }
                }
            }
        }
    }
    
    Rectangle {
        id: progressDialog
        anchors.centerIn: parent
        width: 400
        height: 150
        color: "#1e1e1e"
        radius: 12
        border {
            width: 1
            color: "#333333"
        }
        visible: isDownloading || isInstalling
        z: 100
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            Label {
                text: isDownloading ? "正在下载更新..." : "正在安装更新..."
                font.pointSize: 14
                font.bold: true
                color: "#ffffff"
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                color: "#252525"
                radius: 3
                
                Rectangle {
                    width: parent.width * (parseFloat(downloadProgress) / 100)
                    height: parent.height
                    color: "#3b82f6"
                    radius: 3
                }
            }
            
            Label {
                text: downloadProgress
                font.pointSize: 11
                color: "#3b82f6"
                Layout.alignment: Qt.AlignHCenter
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                
                Label {
                    text: "速度: " + downloadSpeed
                    font.pointSize: 10
                    color: "#9ca3af"
                }
                
                Label {
                    text: "预计时间: " + downloadEta
                    font.pointSize: 10
                    color: "#9ca3af"
                }
            }
        }
    }
    
    Rectangle {
        id: restartDialog
        anchors.centerIn: parent
        width: 350
        height: 150
        color: "#1e1e1e"
        radius: 12
        border {
            width: 1
            color: "#333333"
        }
        visible: statusMessage.includes("安装完成")
        z: 100
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            Label {
                text: "更新完成"
                font.pointSize: 16
                font.bold: true
                color: "#10b981"
                Layout.alignment: Qt.AlignHCenter
            }
            
            Label {
                text: "需要重启应用以完成更新"
                font.pointSize: 11
                color: "#9ca3af"
                Layout.alignment: Qt.AlignHCenter
            }
            
            Button {
                text: "立即重启"
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignHCenter
                background: Rectangle {
                    color: parent.hovered ? "#dc2626" : "#ef4444"
                    radius: 6
                    border {
                        width: 1
                        color: "#f87171"
                    }
                }
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    font.pointSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (updateManager) {
                        updateManager.restartApplication()
                    }
                }
            }
        }
    }

    Rectangle {
        id: updateServerConfig
        anchors.centerIn: parent
        width: 400
        height: 120
        color: "#1e1e1e"
        radius: 12
        border {
            width: 1
            color: "#333333"
        }
        visible: false
        z: 100
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            Label {
                text: "配置更新服务器"
                font.pointSize: 14
                font.bold: true
                color: "#ffffff"
            }
            
            TextField {
                id: serverUrlField
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: "https://your-server.com/updates"
                text: ""
                color: "#ffffff"
                font.pointSize: 11
                background: Rectangle {
                    color: "#252525"
                    radius: 6
                    border {
                        width: 1
                        color: serverUrlField.focus ? "#3b82f6" : "#333333"
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Button {
                    text: "取消"
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 36
                    background: Rectangle {
                        color: parent.hovered ? "#444444" : "#333333"
                        radius: 6
                        border {
                            width: 1
                            color: "#555555"
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font.pointSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        updateServerConfig.visible = false
                    }
                }
                
                Button {
                    text: "确定"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    background: Rectangle {
                        color: parent.hovered ? "#2563eb" : "#3b82f6"
                        radius: 6
                        border {
                            width: 1
                            color: "#60a5fa"
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font.pointSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (updateManager) {
                            updateManager.setUpdateConfig(serverUrlField.text, 86400, false, false, true)
                            updateServerConfig.visible = false
                            checkUpdate()
                        }
                    }
                }
            }
        }
    }

    Label {
        x: 20
        y: 25
        width: parent.width - 40
        height: 30
        text: "关于"
        font.pointSize: 16
        font.bold: true
        color: "#ffffff"
    }

    Rectangle {
        x: 20
        y: 80
        width: parent.width - 40
        height: 270
        color: "#1e1e1e"
        radius: 12
        border {
            width: 1
            color: "#333333"
        }

        Column {
            anchors.fill: parent
            anchors.leftMargin: 25
            anchors.rightMargin: 25
            anchors.topMargin: 20
            anchors.bottomMargin: 20
            spacing: 20

            Item {
                width: parent.width
                height: 20
                
                Label {
                    text: "关于我们"
                    font.pointSize: 12
                    font.bold: true
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Item {
                    width: 28
                    height: 28
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Qt.openUrlExternally("https://github.com/Allen-xxa/ollama_manager")
                    }
                    
                    Image {
                        source: "../assets/img/GitHub_Invertocat_White.svg"
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#333333"
            }

            Item {
                width: parent.width
                height: 100
                
                Image {
                    source: "../../icon.png"
                    sourceSize: Qt.size(100, 100)
                }
                
                Column {
                    x: 115
                    spacing: 15
                    
                    Label {
                        text: "Ollama Manager"
                        font.pointSize: 17
                        font.bold: true
                        color: "#ffffff"
                    }
                    
                    Label {
                        text: "现在，重新定义你的Ollama管理方式！"
                        font.pointSize: 11
                        color: "#9ca3af"
                    }
                    
                    Rectangle {
                        width: (versionLabel.width + 6) * 1.3
                        height: versionLabel.height + 3
                        color: "#1e40af"
                        radius: 3
                        
                        Label {
                            id: versionLabel
                            anchors.centerIn: parent
                            text: "v" + appVersion
                            font.pointSize: 10
                            color: "#4ecdc4"
                        }
                    }
                    
                }
                
                Item {
                    width: 80
                    height: 28
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Rectangle {
                        width: 80
                        height: 28
                        radius: 5
                        color: "#3b82f6"
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: checkUpdate()
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: "检查更新"
                            font.pointSize: 9
                            font.bold: true
                            color: "#ffffff"
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#333333"
            }

            Row {
                spacing: 10
                width: parent.width
                
                Label {
                    text: "自动更新"
                    font.pointSize: 11
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Item {
                    width: parent.width - 72
                    height: parent.height
                    
                    Rectangle {
                        id: autoUpdateToggle
                        width: 40
                        height: 20
                        radius: 10
                        color: autoUpdateEnabled ? "#10b981" : "#6b7280"
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Rectangle {
                            id: autoUpdateThumb
                            width: 17
                            height: 17
                            radius: 8.5
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                            x: autoUpdateEnabled ? parent.width - 19 : 2
                            Behavior on x {
                                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                toggleAutoUpdate()
                            }
                        }
                    }
                }
            }

        }
    }
    
    function checkUpdate() {
        if (updateManager) {
            isChecking = true
            statusMessage = "正在检查更新..."
            updateManager.checkForUpdates()
        }
    }
    
    function showToast(message) {
        var toastQml = `import QtQuick 2.15; 
                       import QtQuick.Controls 2.15;
                       import QtQuick.Layouts 1.15;
                       Rectangle { 
                           id: toastRect
                           implicitWidth: Math.max(200, toastText.width + 40);
                           height: toastText.height + 20;
                           color: "#10b981";
                           radius: 8;
                           border.width: 1;
                           border.color: "#34d399";
                           opacity: 0;
                           anchors.top: parent.top;
                           anchors.topMargin: 20;
                           anchors.horizontalCenter: parent.horizontalCenter;
                           
                           Label { 
                               id: toastText
                               text: "${message}"; 
                               color: "white"; 
                               font.pointSize: 14;
                               wrapMode: Text.Wrap;
                               width: 400;
                               anchors.centerIn: parent;
                           } 
                       }`
        var toast = Qt.createQmlObject(toastQml, aboutPage)
        
        var showAnimation = Qt.createQmlObject('import QtQuick 2.15; NumberAnimation { }', toast)
        showAnimation.target = toast
        showAnimation.property = "opacity"
        showAnimation.from = 0
        showAnimation.to = 1
        showAnimation.duration = 300
        
        var hideAnimation = Qt.createQmlObject('import QtQuick 2.15; NumberAnimation { }', toast)
        hideAnimation.target = toast
        hideAnimation.property = "opacity"
        hideAnimation.from = 1
        hideAnimation.to = 0
        hideAnimation.duration = 300
        
        var timer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 1500; repeat: false }', toast)
        timer.triggered.connect(function() {
            hideAnimation.start()
        })
        
        showAnimation.finished.connect(function() {
            timer.start()
        })
        
        hideAnimation.finished.connect(function() {
            toast.destroy()
        })
        
        showAnimation.start()
    }
}
