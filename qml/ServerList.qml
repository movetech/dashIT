/*
 * Copyright (C) 2013 movetech Systemberatung <info@movetech.net>
 * Copyright (C) 2013 Anton Kreuzkamp <akreuzkamp@web.de>
 *
 * This program is licensed under the terms of the GNU General Public License
 * version 3 or above. See LICENSE.txt.
 */

import QtQuick 1.1

Column {
    spacing: 1

    // Make the list scrollable
    css.overflowX: "hidden"
    css.overflowY: "auto"
    css.pointerEvents: "auto"

    /**
     * Checks for a \p server when the last message has happened and when the
     * next scheduled message should happen, considering the message interval and
     * the configured pauses. The message is considered overdue if the next
     * scheduled message should already have happened.
     *
     * \return true if the message is considered overdue (datetime of the
     *         expected next message is in the past).
     */
    function messageOverdue(server) {
        var lastMessage = new Date(server.history[0].received.replace(' ','T'));
        var expectedNextMessage = new Date(lastMessage.getTime() + server.interval * 3600000); // h to ms
        while (true) {
            if (Date.now() < expectedNextMessage.getTime()) // expectedNextMessage is in the future, so everything is ok
                return false;
            var inPause = false;
            for (var i in server.pauses) {
                if (server.pauses[i].beginWeekday == "-1") {
                    // daily
                    if (server.pauses[i].beginHour > server.pauses[i].endHour)
                        // next day
                        inPause = expectedNextMessage.getHours() >= server.pauses[i].beginHour || expectedNextMessage.getHours() <= server.pauses[i].endHour;
                    else
                        // same day
                        inPause = expectedNextMessage.getHours() >= server.pauses[i].beginHour && expectedNextMessage.getHours() <= server.pauses[i].endHour;
                } else {
                    // weekly
                    if (server.pauses[i].beginWeekday > server.pauses[i].endWeekday)
                        // next week
                        inPause = (expectedNextMessage.getDay() > server.pauses[i].beginWeekday
                                    || (expectedNextMessage.getDay() == server.pauses[i].beginWeekday && expectedNextMessage.getHours() >= server.pauses[i].beginHour))
                                || (expectedNextMessage.getDay() < server.pauses[i].endWeekday
                                    || (expectedNextMessage.getDay() == server.pauses[i].endWeekday && expectedNextMessage.getHours() <= server.pauses[i].endHour));
                    else
                        // same week
                        inPause = (expectedNextMessage.getDay() > server.pauses[i].beginWeekday
                                    || (expectedNextMessage.getDay() == server.pauses[i].beginWeekday && expectedNextMessage.getHours() >= server.pauses[i].beginHour))
                                && (expectedNextMessage.getDay() < server.pauses[i].endWeekday
                                    || (expectedNextMessage.getDay() == server.pauses[i].endWeekday && expectedNextMessage.getHours() <= server.pauses[i].endHour));
                }
                if (inPause) {
                    console.log("Message was in pause!");
                    expectedNextMessage = new Date(expectedNextMessage.getTime() + server.interval * 3600000);
                    break;
                }
            }
            if (!inPause)
                break;
        }
        return true;
    }

// === Description ===
    Text {
        width: parent.width - 20; height: 50
        x: 10
        wrapMode: Text.Wrap
        text: 'Code <code class="green">GRÜN</code> zeigt an, dass das System im letzten Zyklus eine <strong>erfolgreiche</strong> Meldung machte. Code <code class="yellow">GELB</code> zeigt an, dass seit dem letzten Zeitpunkt, an dem eine Meldung erwartet worden wäre, <strong>keine</strong> Meldung erfolgt ist. Code <code class="red">ROT</code> zeigt an, dass die letzte Meldung ein Fehlerbericht war.'
    }

// === Table Header ===
    Row {
        width: parent.width - 50
        x: 10
        spacing: 5

        Text { id: column0; font { bold: true; family: fontFamily; pointSize: fontPointSize } text: "Name";      width: (parent.width - column3.width - column2.width) / 2 }
        Text { id: column1; font { bold: true; family: fontFamily; pointSize: fontPointSize } text: "Sender";    width: (parent.width - column3.width - column2.width) / 2 }
        Text { id: column2; font { bold: true; family: fontFamily; pointSize: fontPointSize } text: "Letzte Meldung"; width: implicitWidth + 60 }
        Text { id: column3; font { family: fontFamily; pointSize: fontPointSize } text: "<b>Historie</b><br><span style=\"float: right\">...ältestes</span>neuestes...";  width: 160 }
    }

// === Server List ===
    Repeater {
        id: serverRepeater
        model: serverModel

        delegate: Rectangle { // This item will be repeated for each item inside the serverModel
            width: parent.width
            border.color: "lightgrey"
            clip: true
            height: openServer == index ? 320 : column0.height + 14
            color: {
                if (history[0].bad == 1)
                    return badColor; // global variable from the config file
                else if (messageOverdue(serverModel.get(index)))
                    return overdueColor;
                else
                    return successfulColor;
            }

            Behavior on height { // Animate each change of the height
                NumberAnimation { duration: 500; easing.type: Easing.InOutExpo }
            }

            // Content
            Row {
                width: parent.width - 20
                x: 10; y: 7
                spacing: 5

                Text { text: name; clip: true; font.family: fontFamily; font.pointSize: fontPointSize; width: column0.width } // Name
                Text { text: sender; clip: true; font.family: fontFamily; font.pointSize: fontPointSize; width: column1.width } // Sender
                Text { text: history[0].received || "Nie"; clip: true; font.family: fontFamily; font.pointSize: fontPointSize; width: column2.width } // Last Message
                Repeater { // History (showing n rectangles indicating the state of the last few messages)
                    model: history.length
                    Rectangle {
                        width: 15; height: 15
                        border.color: "grey"
                        color: parent.history[index].bad == 1
                                ? badColor
                                : successfulColor
                    }
                }
            }

            // Click Area
            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if (openServer == index) {
                        openServer = -1;
                    } else {
                        openServer = index;
                        detailsView.showServer(parent);
                    }
                }
            }
        }
    }

// === Add server ===

    // This rectangle is made for the add server dialog. If you click on the
    // add server button, the ServerEditor is placed into this rectangle.
    Rectangle {
        id: addServerRect
        width: parent.width
        height: 320
        visible: false
    }

    Button {
        text: "Server hinzufügen"
        width: 130; height: 30

        function hide() {
            serverEditor.closed.disconnect(this, hide);
            visible = true;
            addServerRect.visible = false;
        }

        onClicked: {
            addServerRect.visible = true;
            visible = false;
            openServer = -1;
            serverEditor.showServer(addServerRect);
            serverEditor.closed.connect(this, hide);
        }
    }
}