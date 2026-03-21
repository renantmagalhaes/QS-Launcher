pragma ComponentBehavior: Bound

import QtQuick
import "../../Common"
import "../../Services"
import "../../Widgets"

FocusScope {
    id: root

    property var parentModal: null
    property string viewModeContext: "spotlight"
    property alias searchField: searchField
    property alias controller: controller
    property alias resultsList: resultsList
    property alias actionPanel: actionPanel

    function resetScroll() {
        resultsList.resetScroll();
    }

    function focusSearchField() {
        searchField.forceActiveFocus();
    }

    anchors.fill: parent
    focus: true

    QtObject {
        id: actionPanel
        property bool expanded: false
        property bool hasActions: false
        property int selectedActionIndex: 0
        function hide() {
        }
        function show() {
        }
        function cycleAction(reverse) {
        }
        function executeSelectedAction() {
        }
    }

    Controller {
        id: controller
        active: root.parentModal?.spotlightOpen ?? true

        onItemExecuted: {
            if (root.parentModal)
                root.parentModal.hide();
        }
    }

    Keys.onPressed: event => {
        event.accepted = true;
        switch (event.key) {
        case Qt.Key_Escape:
            root.parentModal?.hide();
            return;
        case Qt.Key_Down:
            controller.selectNext();
            return;
        case Qt.Key_Up:
            controller.selectPrevious();
            return;
        case Qt.Key_PageDown:
            controller.selectPageDown(8);
            return;
        case Qt.Key_PageUp:
            controller.selectPageUp(8);
            return;
        case Qt.Key_Tab:
            controller.selectNext();
            return;
        case Qt.Key_Backtab:
            controller.selectPrevious();
            return;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            controller.executeSelected();
            return;
        case Qt.Key_1:
            if (event.modifiers & Qt.ControlModifier) {
                controller.setMode("all");
                return;
            }
            break;
        case Qt.Key_2:
            if (event.modifiers & Qt.ControlModifier) {
                controller.setMode("windows");
                return;
            }
            break;
        case Qt.Key_3:
            if (event.modifiers & Qt.ControlModifier) {
                controller.setMode("apps");
                return;
            }
            break;
        }
        event.accepted = false;
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        DankTextField {
            id: searchField
            width: parent.width
            cornerRadius: Theme.cornerRadius
            backgroundColor: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
            normalBorderColor: Theme.outlineMedium
            focusedBorderColor: Theme.primary
            leftIconName: "search"
            leftIconSize: Theme.iconSize
            leftIconColor: Theme.surfaceVariantText
            leftIconFocusedColor: Theme.primary
            showClearButton: true
            textColor: Theme.surfaceText
            font.pixelSize: Theme.fontSizeLarge
            enabled: root.parentModal ? root.parentModal.spotlightOpen : true
            placeholderText: I18n.tr("Type to search apps")
            ignoreUpDownKeys: true
            ignoreTabKeys: true
            keyForwardTargets: [root]

            onTextChanged: controller.setSearchQuery(text)
        }

        ResultsList {
            id: resultsList
            width: parent.width
            height: parent.height - searchField.height - modeRow.height - Theme.spacingS * 2
            controller: root.controller
        }

        Row {
            id: modeRow
            width: parent.width
            spacing: Theme.spacingS

            Repeater {
                model: [
                    { id: "all", label: I18n.tr("All") },
                    { id: "windows", label: I18n.tr("Windows") },
                    { id: "apps", label: I18n.tr("Apps") }
                ]

                Rectangle {
                    required property var modelData

                    width: label.implicitWidth + Theme.spacingM * 2
                    height: 28
                    radius: Theme.cornerRadius
                    color: controller.searchMode === modelData.id ? Theme.primaryContainer : Theme.surfaceContainerHigh

                    StyledText {
                        id: label
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: Theme.fontSizeSmall
                        color: controller.searchMode === modelData.id ? Theme.primary : Theme.surfaceText
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controller.setMode(modelData.id)
                    }
                }
            }
        }
    }
}
