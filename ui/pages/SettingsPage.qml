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
    // 本地临时设置，用于存储用户修改但未保存的设置
    property var localSettings: {}
    
    // 初始化
    Component.onCompleted: {
        // 获取模型列表
        if (modelManager) {
            modelManager.getModels()
        }
        // 加载设置到本地临时设置
        loadSettingsToLocal()
        // console.log("Settings loaded:", settings)
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
            console.log("Settings loaded to local:", localSettings)
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
                        console.log("Set ComboBox index to", i, "for model", savedModel)
                        return
                    }
                }
                console.log("Saved model not found in list:", savedModel)
            }
            // 如果保存的模型不存在或未设置，选择第一个模型
            ollamaModelComboBox.currentIndex = 0
            localSettings.translation.ollama_model = models[0].name
            console.log("Set ComboBox to first model:", models[0].name)
        }
    }
    
    // 监听模型列表更新
    Connections {
        target: modelManager
        
        function onModelsUpdated(modelList) {
            if (modelManager) {
                models = modelList
                console.log("Models updated:", models.length)
                // 模型列表更新后，先加载设置，再更新 ComboBox 选中值
                loadSettingsToLocal()
                updateComboBoxSelection()
            }
        }
        
        function onSettingsUpdated() {
            if (modelManager) {
                // 强制更新settings属性
                settings = modelManager.settings
                // 同时更新localSettings
                loadSettingsToLocal()
                console.log("Settings updated:", settings)
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
                        console.log("Settings cancelled, reloaded from file")
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
                            modelManager.saveAllSettings(localSettings)
                            console.log("Settings saved to file:", localSettings)
                            // 显示保存成功提示
                            showSaveSuccessToast()
                        }
                    }
                }
            }
            
            // 翻译服务分块容器
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
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
                                    console.log("Google translation selected:", localSettings.translation)
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
                                    console.log("Ollama translation selected:", localSettings.translation)
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
                                            console.log("Selected model:", currentText)
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
                Layout.preferredHeight: 300
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