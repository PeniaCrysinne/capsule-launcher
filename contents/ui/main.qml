import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Qt5Compat.GraphicalEffects as GE
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    // Remove the default dark rectangular widget background
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Sizing constraints for desktop placement
    width: 580
    height: 125
    Layout.minimumWidth: 420
    Layout.preferredWidth: 580
    Layout.maximumWidth: 800
    Layout.minimumHeight: 115
    Layout.preferredHeight: 125
    Layout.maximumHeight: 160

    // Unified item size for both nav buttons and app icon circles
    readonly property int itemSize: Plasmoid.configuration.iconCircleSize || 46

    // Configuration bindings
    readonly property bool stepByPage: Plasmoid.configuration.stepByPage !== undefined ? Plasmoid.configuration.stepByPage : false
    readonly property bool loopNavigation: Plasmoid.configuration.loopNavigation !== undefined ? Plasmoid.configuration.loopNavigation : true
    readonly property bool showTooltip: Plasmoid.configuration.showTooltip !== undefined ? Plasmoid.configuration.showTooltip : true

    fullRepresentation: Item {
        id: container
        anchors.fill: parent

        // Tooltip tracking
        property string activeTooltipText: ""
        property real activeTooltipX: 0
        property bool tooltipVisible: false

        // Motion blur and slide offset when typing in search
        property real motionBlurLength: 0.0
        property real searchSlideOffset: 0.0

        NumberAnimation {
            id: motionBlurAnim
            target: container
            property: "motionBlurLength"
            from: 24.0
            to: 0.0
            duration: 260
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: searchSlideAnim
            target: container
            property: "searchSlideOffset"
            from: 14.0
            to: 0.0
            duration: 220
            easing.type: Easing.OutQuad
        }

        function triggerSearchMotionBlur() {
            motionBlurAnim.stop();
            searchSlideAnim.stop();
            motionBlurAnim.start();
            searchSlideAnim.start();
        }

        // Kicker model integration to retrieve all installed apps
        Kicker.RootModel {
            id: rootModel
            autoPopulate: true
            showAllApps: true
            flat: true
            appletInterface: root

            onCountChanged: {
                loadTimer.restart();
            }
        }

        property var allAppsModel: null
        property var rawAppsList: []
        property var filteredApps: []
        property int currentIndex: 0
        readonly property int visibleCount: 6

        // Debounce timer for loading apps from Kicker RootModel
        Timer {
            id: loadTimer
            interval: 200
            repeat: false
            onTriggered: container.populateApps()
        }

        // Retry timer in case model takes a moment to initialize
        Timer {
            id: retryTimer
            interval: 1000
            repeat: true
            running: container.rawAppsList.length === 0
            onTriggered: {
                if (container.rawAppsList.length === 0) {
                    container.populateApps();
                } else {
                    running = false;
                }
            }
        }

        function populateApps() {
            if (!allAppsModel) {
                for (let i = 0; i < rootModel.count; i++) {
                    let label = rootModel.labelForRow(i);
                    if (label === "All Applications" || label.toLowerCase().indexOf("all") !== -1) {
                        allAppsModel = rootModel.modelForRow(i);
                        break;
                    }
                }
            }

            if (!allAppsModel || allAppsModel.count === 0) return;

            let list = [];
            let count = allAppsModel.count;
            for (let i = 0; i < count; i++) {
                let idx = allAppsModel.index(i, 0);
                let name = allAppsModel.data(idx, 0) || "";
                let icon = allAppsModel.data(idx, 1) || "application-x-executable";
                if (name.length > 0) {
                    list.push({
                        modelIndex: i,
                        name: name,
                        icon: icon
                    });
                }
            }

            // Sort alphabetically by application name
            list.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));
            rawAppsList = list;
            filterApps();
        }

        function filterApps() {
            let q = searchInput.text.trim().toLowerCase();
            if (q === "") {
                filteredApps = rawAppsList;
            } else {
                filteredApps = rawAppsList.filter(app => {
                    return app.name.toLowerCase().indexOf(q) !== -1;
                });
            }
            currentIndex = 0;
            updateScrollPosition(true);
        }

        function launchApp(item) {
            if (!item || !allAppsModel) return;
            allAppsModel.trigger(item.modelIndex, "", null);
        }

        function slotWidth() {
            return appSlotsArea.width > 0 ? (appSlotsArea.width / visibleCount) : 70;
        }

        function updateScrollPosition(immediate) {
            let targetX = currentIndex * slotWidth();
            if (immediate) {
                scrollAnim.stop();
                appsListView.contentX = targetX;
            } else {
                scrollAnim.stop();
                scrollAnim.from = appsListView.contentX;
                scrollAnim.to = targetX;
                scrollAnim.start();
            }
        }

        function navigatePrevious() {
            if (filteredApps.length <= visibleCount) return;
            let step = root.stepByPage ? visibleCount : 1;
            if (currentIndex - step >= 0) {
                currentIndex -= step;
            } else if (root.loopNavigation) {
                currentIndex = Math.max(0, filteredApps.length - visibleCount);
            } else {
                currentIndex = 0;
            }
            updateScrollPosition(false);
        }

        function navigateNext() {
            if (filteredApps.length <= visibleCount) return;
            let step = root.stepByPage ? visibleCount : 1;
            let maxIndex = Math.max(0, filteredApps.length - visibleCount);
            if (currentIndex + step <= maxIndex) {
                currentIndex += step;
            } else if (root.loopNavigation) {
                currentIndex = 0;
            } else {
                currentIndex = maxIndex;
            }
            updateScrollPosition(false);
        }

        NumberAnimation {
            id: scrollAnim
            target: appsListView
            property: "contentX"
            duration: 320
            easing.type: Easing.OutCubic
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            // ==========================================
            // TOP: Pill-Shaped Search Bar
            // ==========================================
            Rectangle {
                id: searchBar
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: height / 2

                // Modern Frosted Glass Aesthetic
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: searchInput.activeFocus ? 
                            Qt.rgba(0.16, 0.20, 0.28, 0.85) : 
                            Qt.rgba(0.12, 0.14, 0.19, 0.65)
                    }
                    GradientStop {
                        position: 1.0
                        color: searchInput.activeFocus ? 
                            Qt.rgba(0.10, 0.13, 0.20, 0.90) : 
                            Qt.rgba(0.08, 0.09, 0.14, 0.75)
                    }
                }

                border.width: 1.5
                border.color: searchInput.activeFocus ? 
                    Kirigami.Theme.highlightColor : 
                    Qt.rgba(1, 1, 1, 0.18)

                Behavior on border.color {
                    ColorAnimation { duration: 180 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 10

                    // Search Magnifier Icon
                    Kirigami.Icon {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        source: "preferences-system-search"
                        color: searchInput.activeFocus ? 
                            Kirigami.Theme.highlightColor : 
                            Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
                    }

                    // Interactive Text Input
                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.pixelSize: 13
                        font.family: Kirigami.Theme.defaultFont.family
                        color: Kirigami.Theme.textColor
                        selectionColor: Kirigami.Theme.highlightColor
                        selectedTextColor: Kirigami.Theme.highlightedTextColor
                        clip: true
                        verticalAlignment: TextInput.AlignVCenter

                        // Placeholder Text
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: i18n("Search applications...")
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.45)
                            font: searchInput.font
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                        }

                        onTextChanged: {
                            container.filterApps();
                            container.triggerSearchMotionBlur();
                        }

                        Keys.onReturnPressed: {
                            if (container.filteredApps.length > 0) {
                                container.launchApp(container.filteredApps[0]);
                            }
                        }

                        Keys.onEscapePressed: {
                            searchInput.text = "";
                            searchInput.focus = false;
                        }
                    }

                    // Result Count Badge (shows when searching)
                    Rectangle {
                        Layout.preferredHeight: 20
                        Layout.preferredWidth: badgeText.implicitWidth + 12
                        radius: height / 2
                        color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.25)
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5)
                        visible: searchInput.text.trim().length > 0

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: container.filteredApps.length.toString()
                            font.pixelSize: 10
                            font.bold: true
                            color: Kirigami.Theme.textColor
                        }
                    }

                    // Clear Button (x)
                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        visible: searchInput.text.length > 0

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: clearMouseArea.containsMouse ? 
                                Qt.rgba(1, 1, 1, 0.22) : 
                                Qt.rgba(1, 1, 1, 0.08)

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 13
                                height: 13
                                source: "edit-clear"
                                color: Kirigami.Theme.textColor
                            }
                        }

                        MouseArea {
                            id: clearMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.focus = true;
                            }
                        }
                    }
                }
            }

            // ==========================================
            // BOTTOM: Pill-Shaped Dock (Uniform Size & Tight Border)
            // ==========================================
            Rectangle {
                id: dockContainer
                Layout.fillWidth: true
                // Height wraps tightly around the items with equal 5px top/bottom padding
                Layout.preferredHeight: root.itemSize + 10
                radius: height / 2

                // Dark Capsule Background
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(0.11, 0.13, 0.18, 0.75)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(0.06, 0.08, 0.12, 0.85)
                    }
                }

                border.width: 1.5
                border.color: Qt.rgba(1, 1, 1, 0.16)

                // Shared Floating Tooltip above hovered icon
                Rectangle {
                    id: sharedTooltipPill
                    visible: root.showTooltip && container.tooltipVisible
                    x: Math.max(16, Math.min(dockContainer.width - width - 16, container.activeTooltipX - width / 2))
                    anchors.bottom: dockContainer.top
                    anchors.bottomMargin: 8
                    width: sharedTooltipText.implicitWidth + 20
                    height: sharedTooltipText.implicitHeight + 8
                    radius: height / 2
                    color: Qt.rgba(0.08, 0.10, 0.14, 0.94)
                    border.width: 1.2
                    border.color: Kirigami.Theme.highlightColor
                    z: 999
                    opacity: visible ? 1.0 : 0.0

                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                    Text {
                        id: sharedTooltipText
                        anchors.centerIn: parent
                        text: container.activeTooltipText
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                // Mouse Wheel Support (scroll left/right or up/down)
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: function(wheel) {
                        if (wheel.angleDelta.y < 0 || wheel.angleDelta.x > 0) {
                            container.navigateNext();
                        } else if (wheel.angleDelta.y > 0 || wheel.angleDelta.x < 0) {
                            container.navigatePrevious();
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 5
                    spacing: 4

                    // --------------------------------------
                    // Left Navigation Arrow Button (<)
                    // Exactly same diameter as app circles
                    // --------------------------------------
                    Item {
                        id: prevBtn
                        Layout.preferredWidth: root.itemSize
                        Layout.preferredHeight: root.itemSize
                        Layout.alignment: Qt.AlignVCenter

                        readonly property bool canGoPrev: container.filteredApps.length > container.visibleCount && (root.loopNavigation || container.currentIndex > 0)
                        opacity: canGoPrev ? (prevMouse.containsMouse ? 1.0 : 0.80) : 0.25

                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: prevMouse.containsMouse ? 
                                Qt.rgba(1, 1, 1, 0.20) : 
                                Qt.rgba(1, 1, 1, 0.06)
                            scale: prevMouse.pressed ? 0.90 : (prevMouse.containsMouse ? 1.10 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: parent.width * 0.44
                                height: parent.height * 0.44
                                source: "go-previous"
                                color: Kirigami.Theme.textColor
                            }
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: prevBtn.canGoPrev ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (prevBtn.canGoPrev) {
                                    container.navigatePrevious();
                                }
                            }
                        }
                    }

                    // --------------------------------------
                    // Center Area: Animated Sliding Apps Area with Motion Blur
                    // --------------------------------------
                    Item {
                        id: appSlotsArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        onWidthChanged: {
                            container.updateScrollPosition(true);
                        }

                        // Message shown when search yields 0 matches
                        Text {
                            anchors.centerIn: parent
                            visible: container.filteredApps.length === 0
                            text: i18n("No applications found")
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.5)
                            font.pixelSize: 12
                            font.italic: true
                        }

                        // Horizontal ListView with smooth slide transition
                        ListView {
                            id: appsListView
                            anchors.fill: parent
                            orientation: ListView.Horizontal
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: false
                            model: container.filteredApps
                            visible: container.filteredApps.length > 0

                            // Horizontal slide offset and subtle streak on search
                            transform: Translate {
                                x: container.searchSlideOffset
                            }

                            // Hardware-accelerated Directional Motion Blur layer
                            layer.enabled: container.motionBlurLength > 0.5
                            layer.effect: GE.DirectionalBlur {
                                angle: 0 // 0 degrees = pure horizontal motion blur
                                length: container.motionBlurLength
                                samples: 16
                            }

                            delegate: Item {
                                id: slotItem
                                width: container.slotWidth()
                                height: appSlotsArea.height

                                readonly property var appData: modelData
                                readonly property bool hasApp: appData !== undefined && appData !== null

                                // Circular container
                                Rectangle {
                                    id: circleBg
                                    anchors.centerIn: parent
                                    width: root.itemSize
                                    height: root.itemSize
                                    radius: width / 2

                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: slotItem.hasApp ? 
                                                (slotMouse.containsMouse ? 
                                                    Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.40) : 
                                                    Qt.rgba(0.24, 0.28, 0.36, 0.65)) : 
                                                Qt.rgba(1, 1, 1, 0.04)
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: slotItem.hasApp ? 
                                                (slotMouse.containsMouse ? 
                                                    Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.20) : 
                                                    Qt.rgba(0.14, 0.16, 0.22, 0.80)) : 
                                                Qt.rgba(1, 1, 1, 0.02)
                                        }
                                    }

                                    border.width: slotItem.hasApp ? (slotMouse.containsMouse ? 1.8 : 1.2) : 1.0
                                    border.color: slotItem.hasApp ? 
                                        (slotMouse.containsMouse ? 
                                            Kirigami.Theme.highlightColor : 
                                            Qt.rgba(1, 1, 1, 0.24)) : 
                                        Qt.rgba(1, 1, 1, 0.06)

                                    scale: slotMouse.pressed ? 0.92 : (slotMouse.containsMouse ? 1.15 : 1.0)

                                    Behavior on scale {
                                        NumberAnimation { duration: 160; easing.type: Easing.OutBack }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation { duration: 140 }
                                    }

                                    // Application Icon inside the circle
                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.62
                                        height: parent.height * 0.62
                                        source: slotItem.hasApp ? slotItem.appData.icon : ""
                                        visible: slotItem.hasApp
                                    }
                                }

                                MouseArea {
                                    id: slotMouse
                                    anchors.fill: parent
                                    hoverEnabled: slotItem.hasApp
                                    cursorShape: slotItem.hasApp ? Qt.PointingHandCursor : Qt.ArrowCursor

                                    onEntered: {
                                        if (slotItem.hasApp) {
                                            let pt = slotItem.mapToItem(dockContainer, slotItem.width / 2, 0);
                                            container.activeTooltipX = pt.x;
                                            container.activeTooltipText = slotItem.appData.name;
                                            container.tooltipVisible = true;
                                        }
                                    }

                                    onExited: {
                                        container.tooltipVisible = false;
                                    }

                                    onClicked: {
                                        if (slotItem.hasApp) {
                                            container.launchApp(slotItem.appData);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --------------------------------------
                    // Right Navigation Arrow Button (>)
                    // Exactly same diameter as app circles
                    // --------------------------------------
                    Item {
                        id: nextBtn
                        Layout.preferredWidth: root.itemSize
                        Layout.preferredHeight: root.itemSize
                        Layout.alignment: Qt.AlignVCenter

                        readonly property bool canGoNext: container.filteredApps.length > container.visibleCount && (root.loopNavigation || container.currentIndex < container.filteredApps.length - container.visibleCount)
                        opacity: canGoNext ? (nextMouse.containsMouse ? 1.0 : 0.80) : 0.25

                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: nextMouse.containsMouse ? 
                                Qt.rgba(1, 1, 1, 0.20) : 
                                Qt.rgba(1, 1, 1, 0.06)
                            scale: nextMouse.pressed ? 0.90 : (nextMouse.containsMouse ? 1.10 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: parent.width * 0.44
                                height: parent.height * 0.44
                                source: "go-next"
                                color: Kirigami.Theme.textColor
                            }
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: nextBtn.canGoNext ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (nextBtn.canGoNext) {
                                    container.navigateNext();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
