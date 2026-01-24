import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: settingsPage
    property string currentPage: "settings"
    width: parent.width
    height: parent.height
    color: "#121212"
    
    // 监听页面可见性变化
    onVisibleChanged: {
        if (visible) {
            // 页面变为可见时，重新加载设置并更新 ComboBox 选中值
            loadSettingsToLocal()
            updateComboBoxSelection()
            // console.log("Settings page became visible, updated ComboBox selection")
        }
    }
    
    // 页面数据
    property var models: []
    property var settings: modelManager ? modelManager.settings : {}
    property var updateSettings: updateManager ? {} : {}
    property bool developerMode: false
    // 本地临时设置，用于存储用户修改但未保存的设置
    property var localSettings: {}
    
    // 初始化
    Component.onCompleted: {
        // console.log("------------------设置页初始化------------------")
        // 获取模型列表
        if (modelManager) {
            modelManager.getModels()
        }
        // 加载设置到本地临时设置
        loadSettingsToLocal()
        // 加载更新管理器设置
        loadUpdateSettings()
        // console.log("Settings loaded:", settings)
        // 注意：最终结束分隔符会在功能完成时自动添加
    }
    
    // 从 modelManager.settings 加载设置到 localSettings
    function loadSettingsToLocal() {
        if (modelManager && modelManager.settings) {
            // 深拷贝设置对象
            localSettings = JSON.parse(JSON.stringify(modelManager.settings))
            // 确保 translation 对象存在
            if (!localSettings.translation) {
                localSettings.translation = {
                    "google_translation": true,
                    "ollama_translation": false,
                    "ollama_model": "",
                    "ollama_prompt": "你是一个专业的翻译助手，请将以下内容翻译成中文，保持原文的意思和风格："
                }
            }
            // 确保 developer_mode 存在
            if (localSettings.developer_mode === undefined) {
                localSettings.developer_mode = false
            }
            // console.log("📋 设置已加载到本地")
        }
    }
    
    // 更新 ComboBox 选中值
    function updateComboBoxSelection() {
        if (localSettings.translation && models.length > 0) {
            var savedModel = localSettings.translation.ollama_model
            if (savedModel) {
                for (var i = 0; i < models.length; i++) {
                    if (models[i].name === savedModel) {
                        ollamaModelComboBox.currentIndex = i
                        // console.log("🔄 已将 ComboBox 索引设置为 " + i + "，对应模型 " + savedModel)
                        return
                    }
                }
                // console.log("⚠️  保存的模型未在列表中找到：" + savedModel)
            }
            // 如果保存的模型不存在或未设置，选择第一个模型
            ollamaModelComboBox.currentIndex = 0
            localSettings.translation.ollama_model = models[0].name
            // console.log("🔄 已将 ComboBox 设置为第一个模型：" + models[0].name)
        }
    }
    
    // 加载更新管理器设置
    function loadUpdateSettings() {
        if (modelManager && modelManager.settings) {
            var settings = modelManager.settings
            var updateConfig = settings.update || {}
            developerMode = updateConfig.developer_mode || false
            // console.log("🔄 更新设置已加载，开发者模式：" + developerMode)
        }
    }
    
    // 监听模型列表更新
    Connections {
        target: modelManager
        
        function onModelsUpdated(modelList) {
            if (modelManager) {
                models = modelList
                // console.log("📋 模型已更新：" + models.length)
                // 模型列表更新后，先加载设置，再更新 ComboBox 选中值
                loadSettingsToLocal()
                updateComboBoxSelection()
                // 添加结束分割线
                // console.log("--------------------------------------------------\n")
            }
        }
        
        function onSettingsUpdated() {
            if (modelManager) {
                // 强制更新settings属性
                settings = modelManager.settings
                // 同时更新localSettings
                loadSettingsToLocal()
                // 重新加载更新设置
                loadUpdateSettings()
                // console.log("📋 设置已加载到本地")
            }
        }
    }
    
    // 监听更新管理器
    Connections {
        target: updateManager
        
        function onSettingsUpdated() {
            if (updateManager) {
                // console.log("🔄 更新管理器设置已更新")
            }
        }
    }
    
    // 页面滚动容器
    Flickable {
        id: pageFlickable
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: width
        contentHeight: mainColumn.height
        clip: true
        
        // 垂直滚动条
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 8
            hoverEnabled: true
            visible: pageFlickable.contentHeight > pageFlickable.height
            
            background: Rectangle {
                color: "#1e1e1e"
                radius: 4
            }
            
            contentItem: Rectangle {
                color: "#3b82f6"
                radius: 4
            }
        }
        
        ColumnLayout {
            id: mainColumn
            width: parent.width
            spacing: 20
        
            // 顶部标题和按钮区域
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Label {
                    text: "设置"
                    font.pointSize: 16
                    font.bold: true
                    color: "#ffffff"
                }
                
                Item {
                    Layout.fillWidth: true
                }
                
                // 取消按钮
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
                        // 重新加载设置，放弃未保存的修改
                        loadSettingsToLocal()
                        // console.log("🔄 设置已取消，从文件重新加载")
                    }
                }
                
                // 保存按钮
                Button {
                    text: "保存"
                    Layout.preferredWidth: 80
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
                        // 保存设置到文件
                        if (modelManager) {
                            // 根据开发者模式设置正确的服务器地址
                            var serverUrl = updateManager ? updateManager.updateServer : ''
                            if (developerMode) {
                                // 开发者模式：使用本地路径
                                serverUrl = "G:\\AI-Code-test\\更新测试包"
                            } else {
                                // 非开发者模式：使用 GitHub
                                serverUrl = "https://github.com/Allen-xxa/ollama_manager/releases"
                            }
                            
                            // 将开发者模式设置添加到localSettings中
                            localSettings.update = {
                                'update_server': serverUrl,
                                'check_interval': updateManager ? updateManager.checkInterval : 86400,
                                'auto_download': updateManager ? updateManager.autoDownload : false,
                                'auto_install': updateManager ? updateManager.autoInstall : false,
                                'backup_enabled': updateManager ? updateManager.backupEnabled : true,
                                'developer_mode': developerMode
                            }
                            modelManager.saveAllSettings(localSettings)
                            // 重新加载更新管理器配置
                            if (updateManager) {
                                updateManager.reloadConfig()
                            }
                            // console.log("📋 开发者模式已保存：" + developerMode)
                            // console.log("📋 更新服务器地址：" + serverUrl)
                            // console.log("📋 设置已保存到文件")
                            // 显示保存成功提示
                            showSaveSuccessToast()
                        }
                    }
                }
            }
            
            // 代理设置分块容器
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 140
                color: "#1e1e1e"
                radius: 12
                border {
                    width: 1
                    color: "#333333"
                }
                visible: false
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15
                    
                    // 标题
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Label {
                            text: "代理设置"
                            font.pointSize: 14
                            font.bold: true
                            color: "#ffffff"
                        }
                    }
                    
                    // 分割线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: "#333333"
                    }
                    
                    // 代理服务器设置
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Label {
                            Layout.preferredWidth: 100
                            text: "代理服务器:" 
                            font.pointSize: 12
                            color: "#ffffff"
                            Layout.alignment: Qt.AlignVCenter
                        }
                        
                        // 代理类型下拉选择
                        ComboBox {
                            id: proxyTypeComboBox
                            Layout.preferredWidth: 150
                            model: ["关闭", "系统代理", "自定义"]
                            background: Rectangle {
                                color: "#333333"
                                radius: 6
                                border {
                                    width: 1
                                    color: "#444444"
                                }
                            }
                            contentItem: Text {
                                text: parent.displayText
                                color: "#ffffff"
                                font.pointSize: 12
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                                leftPadding: 10
                                rightPadding: 10
                            }
                            delegate: ItemDelegate {
                                width: parent.width
                                padding: 10
                                contentItem: Text {
                                    text: modelData
                                    color: "#ffffff"
                                    font.pointSize: 12
                                }
                                background: Rectangle {
                                    color: "#333333"
                                    border {
                                        width: 1
                                        color: "#444444"
                                    }
                                }
                            }
                            
                            // 初始化currentIndex
                            Component.onCompleted: {
                                if (localSettings && localSettings.proxy) {
                                    switch (localSettings.proxy.type) {
                                        case "none":
                                            currentIndex = 0
                                            break
                                        case "system":
                                            currentIndex = 1
                                            break
                                        case "custom":
                                            currentIndex = 2
                                            break
                                        default:
                                            currentIndex = 1
                                            break
                                    }
                                } else {
                                    currentIndex = 1
                                }
                            }
                            
                            onCurrentIndexChanged: {
                                // 更新本地临时设置
                                if (!localSettings) {
                                    localSettings = {}
                                }
                                if (!localSettings.proxy) {
                                    localSettings.proxy = {}
                                }
                                
                                switch (currentIndex) {
                                    case 0:
                                        localSettings.proxy.type = "none"
                                        break
                                    case 1:
                                        localSettings.proxy.type = "system"
                                        break
                                    case 2:
                                        localSettings.proxy.type = "custom"
                                        break
                                }
                            }
                        }
                        
                        // 自定义代理地址输入框
                        TextField {
                            id: customProxyInput
                            visible: proxyTypeComboBox.currentIndex === 2
                            Layout.fillWidth: true
                            placeholderText: "http://127.0.0.1:7890"
                            text: localSettings && localSettings.proxy && localSettings.proxy.type === "custom" ? localSettings.proxy.address : ""
                            color: "#ffffff"
                            font.pointSize: 12
                            leftPadding: 10
                            rightPadding: 10
                            background: Rectangle {
                                color: "#333333"
                                radius: 6
                                border {
                                    width: 1
                                    color: "#444444"
                                }
                            }
                            onTextChanged: {
                                // 更新本地临时设置
                                if (!localSettings) {
                                    localSettings = {}
                                }
                                if (!localSettings.proxy) {
                                    localSettings.proxy = {}
                                }
                                localSettings.proxy.address = text
                            }
                        }
                    }
                }
            }
            
            // 翻译服务分块容器
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                color: "#1e1e1e"
                radius: 12
                border {
                    width: 1
                    color: "#333333"
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10
                    
                    // 标题
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Label {
                            text: "翻译服务"
                            font.pointSize: 14
                            font.bold: true
                            color: "#ffffff"
                        }
                    }
                    
                    // 分割线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: "#333333"
                    }
                    
                    // 子块容器
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10
                        
                        // Google翻译
                        Rectangle {
                            id: googleTranslationContainer
                            width: 300
                            Layout.fillHeight: true
                            property bool active: localSettings.translation ? localSettings.translation.google_translation : false
                            color: active ? "#333333" : "#252525"
                            radius: 8
                            border {
                                width: 1
                                color: active ? "#3b82f6" : "#333333"
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    // 确保localSettings.translation存在
                                    if (!localSettings.translation) {
                                        localSettings.translation = {
                                            "google_translation": true,
                                            "ollama_translation": false,
                                            "ollama_model": "",
                                            "ollama_prompt": "你是一个专业的翻译助手，请将以下内容翻译成中文，保持原文的意思和风格："
                                        }
                                    }
                                    localSettings.translation.google_translation = true
                                    localSettings.translation.ollama_translation = false
                                    // console.log("🔄 已选择 Google 翻译")
                                    // 强制更新UI
                                    googleTranslationContainer.active = true
                                    ollamaTranslationContainer.active = false
                                }
                                onEntered: {
                                    if (!googleTranslationContainer.active) {
                                        googleTranslationContainer.color = "#2a2a2a"
                                    }
                                }
                                onExited: {
                                    if (!googleTranslationContainer.active) {
                                        googleTranslationContainer.color = "#252525"
                                    }
                                }
                            }
                            
                            Label {
                                anchors.centerIn: parent
                                text: "Google翻译"
                                font.pointSize: 12
                                color: "#ffffff"
                            }
                        }
                        
                        // ollama翻译
                        Rectangle {
                            id: ollamaTranslationContainer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            property bool active: localSettings.translation ? localSettings.translation.ollama_translation : false
                            color: active ? "#333333" : "#252525"
                            radius: 8
                            border {
                                width: 1
                                color: active ? "#3b82f6" : "#333333"
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    // 确保localSettings.translation存在
                                    if (!localSettings.translation) {
                                        localSettings.translation = {
                                            "google_translation": false,
                                            "ollama_translation": true,
                                            "ollama_model": "",
                                            "ollama_prompt": "你是一个专业的翻译助手，请将以下内容翻译成中文，保持原文的意思和风格："
                                        }
                                    }
                                    localSettings.translation.google_translation = false
                                    localSettings.translation.ollama_translation = true
                                    // console.log("🔄 已选择 Ollama 翻译")
                                    // 强制更新UI
                                    googleTranslationContainer.active = false
                                    ollamaTranslationContainer.active = true
                                }
                                onEntered: {
                                    if (!ollamaTranslationContainer.active) {
                                        ollamaTranslationContainer.color = "#2a2a2a"
                                    }
                                }
                                onExited: {
                                    if (!ollamaTranslationContainer.active) {
                                        ollamaTranslationContainer.color = "#252525"
                                    }
                                }
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 10
                                
                                Label {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "ollama翻译"
                                    font.pointSize: 12
                                    color: "#ffffff"
                                }
                                
                                ComboBox {
                                    id: ollamaModelComboBox
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    model: models
                                    textRole: "name"
                                    background: Rectangle {
                                        color: "#333333"
                                        radius: 6
                                        border {
                                            width: 1
                                            color: "#444444"
                                        }
                                    }
                                    contentItem: Text {
                                        text: parent.displayText
                                        color: "#ffffff"
                                        font.pointSize: 12
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignLeft
                                        elide: Text.ElideRight
                                        leftPadding: 10
                                        rightPadding: 10
                                    }
                                    delegate: ItemDelegate {
                                        width: parent.width
                                        padding: 10
                                        contentItem: Text {
                                            text: modelData.name || "未知模型"
                                            color: "#ffffff"
                                            font.pointSize: 12
                                            elide: Text.ElideRight
                                        }
                                        background: Rectangle {
                                            color: "#333333"
                                            border {
                                                width: 1
                                                color: "#444444"
                                            }
                                        }
                                    }
                                    Component.onCompleted: {
                                        // 加载保存的模型
                                        updateComboBoxSelection()
                                    }
                                    onCurrentTextChanged: {
                                        // 更新本地临时设置
                                        if (localSettings.translation) {
                                            localSettings.translation.ollama_model = currentText
                                            // console.log("🔄 已选择模型：" + currentText)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // 提示词分块容器
            Rectangle {
                id: promptContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 320
                color: "#1e1e1e"
                radius: 12
                border {
                    width: 1
                    color: "#333333"
                }
                visible: localSettings.translation ? localSettings.translation.ollama_translation : false
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    // 标题
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Label {
                            text: "提示词设置"
                            font.pointSize: 14
                            font.bold: true
                            color: "#ffffff"
                        }
                    }
                    
                    // 分割线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: "#333333"
                    }
                    
                    // 提示词编辑区域
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#252525"
                        radius: 8
                        border {
                            width: 1
                            color: "#333333"
                        }
                        
                        TextEdit {
                            id: promptTextEdit
                            anchors.fill: parent
                            anchors.margins: 10
                            color: "#ffffff"
                            font.pointSize: 12
                            wrapMode: TextEdit.Wrap
                            onTextChanged: {
                                // 更新本地临时设置
                                if (localSettings.translation) {
                                    localSettings.translation.ollama_prompt = text
                                }
                            }
                            Component.onCompleted: {
                                if (localSettings.translation && localSettings.translation.ollama_prompt) {
                                    text = localSettings.translation.ollama_prompt
                                } else {
                                    // 设置默认提示词
                                    text = "你是一个专业的翻译助手，请将以下内容翻译成中文，保持原文的意思和风格："
                                    if (localSettings.translation) {
                                        localSettings.translation.ollama_prompt = text
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // 开发者模式分块容器
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: "#1e1e1e"
                radius: 12
                border {
                    width: 1
                    color: "#333333"
                }
                visible: debugMode  // 根据debugMode控制可见性
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10
                    
                    // 标题
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Label {
                            text: "开发者模式"
                            font.pointSize: 14
                            font.bold: true
                            color: "#ffffff"
                        }
                    }
                    
                    // 分割线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: "#333333"
                    }
                    
                    // 调试文本和开关
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10
                        
                        Label {
                            text: "调试"
                            font.pointSize: 11
                            color: "#ffffff"
                            Layout.alignment: Qt.AlignVCenter
                        }
                        
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            
                            Rectangle {
                                width: 40
                                height: 20
                                radius: 10
                                color: developerMode ? "#10b981" : "#333333"
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Rectangle {
                                    width: 17
                                    height: 17
                                    radius: 8.5
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: developerMode ? parent.width - 19 : 2
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        // console.log("🔧 调试按钮已点击，当前开发者模式：" + developerMode)
                                        developerMode = !developerMode
                                        // console.log("🔧 新开发者模式值：" + developerMode)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 显示保存成功提示
    function showSaveSuccessToast() {
        // 创建临时的提示消息
        var toast = Qt.createQmlObject('import QtQuick 2.15; import QtQuick.Controls 2.15; Rectangle { width: 200; height: 50; color: "#10b981"; radius: 8; border.width: 1; border.color: "#34d399"; opacity: 0; anchors.centerIn: parent; Text { text: "保存成功"; color: "white"; font.pointSize: 14; anchors.centerIn: parent } }', settingsPage)
        
        // 显示动画
        var showAnimation = Qt.createQmlObject('import QtQuick 2.15; NumberAnimation { }', toast)
        showAnimation.target = toast
        showAnimation.property = "opacity"
        showAnimation.from = 0
        showAnimation.to = 1
        showAnimation.duration = 300
        
        // 隐藏动画
        var hideAnimation = Qt.createQmlObject('import QtQuick 2.15; NumberAnimation { }', toast)
        hideAnimation.target = toast
        hideAnimation.property = "opacity"
        hideAnimation.from = 1
        hideAnimation.to = 0
        hideAnimation.duration = 300
        
        // 创建定时器
        var timer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 1500; repeat: false }', toast)
        timer.triggered.connect(function() {
            hideAnimation.start()
        })
        
        // 连接动画信号
        showAnimation.finished.connect(function() {
            timer.start()
        })
        
        hideAnimation.finished.connect(function() {
            toast.destroy()
        })
        
        // 启动显示动画
        showAnimation.start()
    }
}