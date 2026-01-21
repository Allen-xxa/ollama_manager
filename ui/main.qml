import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1400
    height: 900
    title: "Ollama 模型管理器"
    color: "#121212"
    
    // 加载字体
    FontLoader {
        id: msyhFont
        source: "assets/fonts/msyh.ttc"
    }
    
    // 设置全局字体
    font.family: msyhFont.name

    property string currentPage: "dashboard"

    Rectangle {
        anchors.fill: parent
        color: "#121212"
        // 左侧导航栏
        Loader {
            id: navBarLoader
            source: "components/NavBar.qml"
            x: 0
            y: 0
            width: 200
            height: parent.height
            onLoaded: {
                item.currentPage = mainWindow.currentPage
                item.pageChanged.connect(function(page) {
                    mainWindow.currentPage = page
                })
            }
        }
        
        // 监听页面变化，更新导航栏状态
        Connections {
            target: mainWindow
            function onCurrentPageChanged() {
                if (navBarLoader.item) {
                    navBarLoader.item.currentPage = mainWindow.currentPage
                }
            }
        }
        // 右侧内容区域
        Loader {
            id: pageLoader
            x: navBarLoader.width
            y: 0
            width: parent.width - navBarLoader.width
            height: parent.height
            source: {
                if (currentPage === "dashboard") return "pages/DashboardPage.qml"
                else if (currentPage === "modelLibrary") return "pages/ModelLibraryPage.qml"
                else if (currentPage === "modelDetail") return "pages/ModelDetailPage.qml"
                else if (currentPage === "modelAllVersions") return "pages/ModelAllVersionsPage.qml"
                else if (currentPage === "serverManagement") return "pages/ServerManagerPage.qml"
                else if (currentPage === "downloadManager") return "pages/DownloadManagerPage.qml"
                else if (currentPage === "addAssistant") return "pages/AddAssistantPage.qml"
                else if (currentPage === "defaultAssistant") return "pages/DefaultAssistantPage.qml"
                else if (currentPage === "settings") return "pages/SettingsPage.qml"
                else if (currentPage === "about") return "pages/AboutPage.qml"
                else return "components/ModelManager/ModelManagerPage.qml"
            }
            onLoaded: {
                if (item) {
                    // 只在页面有currentPage属性时才赋值
                    if (item.hasOwnProperty("currentPage")) {
                        item.currentPage = mainWindow.currentPage
                    }
                    // 连接页面变更信号
                    if (item.pageChanged) {
                        item.pageChanged.connect(function(page) {
                            mainWindow.currentPage = page
                        })
                    }
                }
            }
        }
    }
}