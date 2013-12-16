/*
 * Copyright (C) 2013 movetech Systemberatung <info@movetech.net>
 * Copyright (C) 2013 Anton Kreuzkamp <akreuzkamp@web.de>
 *
 * This program is licensed under the terms of the GNU General Public License
 * version 3 or above. See LICENSE.txt.
 */

import QtQuick 1.1

Item {

    /**
     * Places the details view to the specified \p serverItem and refreshes
     * this details view to show the details of that item by filing an
     * AJAX-request to the server, asking for the data about this server. That
     * is an overview over the messages from that server from the last
     * month.
     */
    function showServer(serverItem) {
        parent = serverItem;
        serverEditor.closed();
        visible = true;
        showDate(new Date());
        calendar.loading = true;
        $.ajax("api.php/servers/" + serverModel.get(openServer).serverId, {
            success: function(data) {
                var list = JSON.parse(data);
                calendar.data = {};
                for (var i in list) {
                    var date = list[i].received.split(" ")[0];
                    if (calendar.data[date] !== true)
                        calendar.data[date] = Number(list[i].bad);
                }
                calendar.setDate(new Date());
                calendar.refresh();
                calendar.loading = false;
            }
        });
    }

    /**
     * Lists the messages of a specific \p date in the right part of the view.
     * This functions files an AJAX-request to the server asking for the
     * messages of the currently open server and the specified \p date.
     */
    function showDate(date) {
        loadingMessagesImage.opacity = 1;
        messageModel.clear();
        messageView.opacity = 0;
        messageList.css.mozFilter = "none";
        messageList.css.webkitFilter = "none";
        messageList.css.filter = "none";
        $.ajax("api.php/servers/" + serverModel.get(openServer).serverId + "/" + date.getFullYear() + "/" + (date.getMonth() + 1) + "/" + date.getDate(), {
            success: function(data) {
                var list = JSON.parse(data);
                for (var i in list) {
                    messageModel.append(list[i]);
                }
                loadingMessagesImage.opacity = 0;
            }
        });
    }

// === Calendar ===
    Calendar {
        id: calendar
        property variant data: {}

        onSelected: parent.showDate(date);
        onChangedMonthYear: {
            loading = true;
            $.ajax("api.php/servers/" + serverModel.get(openServer).serverId + "/" + year + "/" + month, {
                success: function(serverData) {
                    var list = JSON.parse(serverData);
                    data = {};
                    for (var i in list) {
                        var date = list[i].received.split(" ")[0];
                        if (data[date] !== true)
                            data[date] = Number(list[i].bad);
                    }
                    refresh();
                    loading = false;
                }
            });
        }
        beforeShowDay: (function(date) {
            var dateString = (new Date(date - date.getTimezoneOffset() * 60000)).toISOString().split("T")[0];
            if (data[dateString] === 1)
                return [true, "calendar-date-red", "Min. 1 fehlerhaftes Backup an diesem Tag"];
            else if (data[dateString] === 0)
                return [true, "calendar-date-green", "Min 1 erfolgreiches u. kein fehlerhaftes Backup an diesem Tag"];
            else
                return [true, "calendar-date-yellow", "Keine Backupbenachrichtigung an diesem Tag"];
        })
    }

// === Edit Server Button ===
    Button {
        id: editServerButton
        anchors { top: calendar.bottom; topMargin: 10 }
        text: "Server editieren"
        width: 150; height: 25

        function hide() {
            serverEditor.closed.disconnect(this, hide);
            detailsView.visible = true;
        }

        onClicked: {
            serverEditor.showServer(parent.parent);
            serverEditor.closed.connect(this, hide);
        }
    }

// === Message List ===
    Column {
        id: messageList
        width: parent.width - calendar.width - 40
        height: calendar.height
        anchors.left: calendar.right
        anchors.leftMargin: 20
        spacing: 1

        // Make the list scrollable
        css.overflowX: "hidden"
        css.overflowY: "auto"
        css.pointerEvents: "auto"

        ListModel {
            id: messageModel
        }

        // Table Header
        Row {
            width: parent.width - 20
            x: 10; y: (30 - height) / 2

            Text { font.bold: true; width: 200; text: "Zeitpunkt" }
            Text { font.bold: true; width: 200; text: "E-Mail-Betreff" }
        }

        // Message List
        Repeater {
            model: messageModel

            delegate: Rectangle { // This item will be repeated for each item inside the messageModel
                width: parent.width - 2 // -2 for border
                height: 30
                color: bad == 1 ? "red": "greenyellow"
                border.color: "lightgrey"

                Behavior on height {
                    NumberAnimation { duration: 250 }
                }

                // Content
                Row {
                    width: parent.width - 20
                    x: 10; y: (30 - height) / 2

                    Text { text: received; width: 200 }
                    Text { text: subject; width: parent.width - 200 }
                }

                // Click Area
                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        // Highlight text matching the rules (Mark why the message is bas)
                        var text = message;
                        if (bad === "1") {
                            for (var i in serverModel.get(openServer).rules) {
                                var rule = serverModel.get(openServer).rules[i];
                                if (rule[0] == '/') { // regular expressions
                                    var regexEnd = rule.lastIndexOf('/');
                                    var pattern = new RegExp("(" + rule.substring(1, regexEnd) + ")", rule.substring(regexEnd + 1)); // Transfer php regex-string to js regex-string
                                    text = text.replace(pattern, "<span class=\"highlighted\"><u>$1</span>");
                                } else { // simple text rules
                                    text = text.split(rule).join("<span class=\"highlighted\">" + rule + "</span>"); // == search & replace all
                                }
                            }
                        }
                        messageView.messageText = "<b>" + subject + "</b><br><br>" + text + "<br><br>";
                        messageList.css.mozFilter = "blur(5px)";
                        messageList.css.webkitFilter = "blur(5px)";
                        messageList.css.filter = "blur(5px)";
                        messageView.opacity = 1;
                    }
                }
            }
        }

        // Text to be shown if there is no message.
        Text {
            text: "Keine Backup-Benachrichtigungen an diesem Tag."
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: messageModel.count || loadingMessagesImage.opacity ? 0 : 1

            Behavior on opacity { // Animate each change of the opacity
                NumberAnimation { duration: 250 }
            }
        }
    }

// === Message View ===
    Rectangle {
        id: messageView
        anchors.fill: messageList
        color: Qt.rgba(255,255,255,0.7)
        border.color: "lightgrey"
        visible: opacity // If opacity is 0 hide it completely, so it can't be clicked
        opacity: 0

        property string messageText

        Behavior on opacity { // Animate each change of the opacity
            NumberAnimation { duration: 250 }
        }

        // Message
        Text {
            id: messageLabel
            anchors.fill: parent
            anchors.margins: 5
            wrapMode: Text.Wrap
            text: messageView.messageText

            // make message scrollable
            css.overflowX: "hidden"
            css.overflowY: "auto"
            css.pointerEvents: "auto"
        }

        // Close Button
        Image {
            source: "../style/close.png"
            width: 24; height: 24
            anchors { top: parent.top; right: parent.right; rightMargin: 30; topMargin: 10 }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    messageView.opacity = 0;
                    messageList.css.mozFilter = "none";
                    messageList.css.webkitFilter = "none";
                    messageList.css.filter = "none";
                }
            }
        }
    }

    // Loading Indicator
    Image {
        id: loadingMessagesImage
        width: 24; height: 24
        anchors.centerIn: messageList
        source: "../style/loading.gif"
        opacity: 0

        Behavior on opacity { // Animate each change of the opacity
            NumberAnimation { duration: 250 }
        }
    }
}