/*
 * Copyright (C) 2013 movetech Systemberatung <info@movetech.net>
 * Copyright (C) 2013 Anton Kreuzkamp <akreuzkamp@web.de>
 *
 * This program is licensed under the terms of the GNU General Public License
 * version 3 or above. See LICENSE.txt.
 */

import QtQuick 1.1

Item {
    clip: true
    property variant server: serverModel.get(openServer) || {}

    signal closed()

    onClosed: {
        parent = root;
        visible = false;
    }

    /**
     * Places this server editor to the specified \p serverItem and refreshes
     * this editor to show the details of that item and providing an UI to edit
     * that server.
     */
    function showServer(serverItem) {
        detailsView.visible = false;
        parent = serverItem;
        visible = true;
        rulesModel.clear();
        for (var i in server.rules)
            rulesModel.append({ rule: server.rules[i]});
        pausesModel.clear();
        for (var i in server.pauses)
            pausesModel.append(server.pauses[i]);
    }

    /**
     * Applies the changes.
     * This function files a request to the REST-API, asking either
     * - to change a server
     * - to add a server
     *
     * When the server is added/changed, the server list will be reloaded and
     * the server editor will be closed.
     */
    function applyChanges() {
        // Fetch rules from rules list
        var rules = [];
        for (var i = 0; i < rulesModel.count; i++) {
            rules.push(rulesRepeater.itemAt(i).children[0].text);
        }
        // Fetch and parse pauses from the pauses list.
        var weekdays = { "": -1, "*": -1, 1: 1, Mo: 1, Mon: 1, 2: 2, Di: 2, Tue: 2, 3: 3, Mi: 3, Wed: 3, 4: 4, Do: 4, Thu: 4,
                         5: 5, Fr: 5, Fri: 5, 6: 6, Sa: 6, Sat: 6, 0: 0, So: 0, Sun: 0 };
        var pauses = [];
        for (var i = 0; i < pausesModel.count; i++) {
            pauses.push({
                beginWeekday: weekdays[pausesRepeater.itemAt(i).children[0].text],
                beginHour: pausesRepeater.itemAt(i).children[1].text,
                endWeekday: weekdays[pausesRepeater.itemAt(i).children[3].text],
                endHour: pausesRepeater.itemAt(i).children[4].text
            });
        }
        // File request
        if (openServer == -1) {
            $.ajax("api.php/servers", {
                type: "POST",
                data: {
                    name: serverName.text,
                    sender: serverSender.text,
                    interval: serverInterval.text,
                    rules: rules,
                    pauses: pauses
                },
                success: function(data) {
                    closed();
                    reloadServerList();
                }
            });
        } else {
            $.ajax("api.php/servers/" + serverModel.get(openServer).serverId, {
                type: "PUT",
                data: JSON.stringify({
                    name: serverName.text,
                    sender: serverSender.text,
                    interval: serverInterval.text,
                    rules: rules,
                    pauses: pauses
                }),
                success: function(data) {
                    closed();
                    reloadServerList();
                }
            });
        }
    }

// === General Data ===
    Grid {
        id: generalDataGrid
        spacing: 10
        columns: 2

        Text { text: "Name:" }
        TextInput {
            id: serverName
            width: 200
            text: server.name || ""
        }

        Text { text: "Absendeadresse:" }
        TextInput {
            id: serverSender
            width: 200
            text: server.sender || ""
        }

        Text { text: "Intervall (in h):" }
        TextInput {
            id: serverInterval
            width: 50
            text: server.interval || "24"
        }
    }

// === Pauses ===
    Column {
        width: 500
        anchors.top: generalDataGrid.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 20
        spacing: 5
        css.overflowX: "hidden"
        css.overflowY: "auto"
        css.pointerEvents: "auto"

        // Header
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            text: "<b>Ausnahmen</b>\n(Bsp.: Sa 0 - So 23)"
        }

        ListModel {
            id: pausesModel
            ListElement { beginWeekday: "Sa"; beginHour: "0"; endWeekday: "So"; endHour: "23" }
        }

        // Table Header
        Row {
            width: parent.width
            spacing: 10
            Text { width: (parent.width - 100) / 4; text: "Wochentag";  horizontalAlignment: Text.AlignHCenter }
            Text { width: (parent.width - 100) / 4; text: "Stunde";     horizontalAlignment: Text.AlignHCenter }
            Text { width: 5;                        text: "-";          horizontalAlignment: Text.AlignHCenter }
            Text { width: (parent.width - 100) / 4; text: "Wochentag";  horizontalAlignment: Text.AlignHCenter }
            Text { width: (parent.width - 100) / 4; text: "Stunde";     horizontalAlignment: Text.AlignHCenter }
        }

        // Pauses List
        Repeater {
            id: pausesRepeater
            model: pausesModel

            Row {
                width: parent.width
                spacing: 10
                TextInput {
                    id: beginWeekdayEdit
                    width: (parent.width - 100) / 4
                    text: (["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"])[beginWeekday] // Display weekday number as name (e.g. 1 to Mo)
                }
                TextInput {
                    id: beginHourEdit
                    width: (parent.width - 100) / 4
                    text: beginHour
                }
                Text { width: 5; text: "-"; horizontalAlignment: Text.AlignHCenter }
                TextInput {
                    id: endWeekdayEdit
                    width: (parent.width - 100) / 4
                    text: (["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"])[endWeekday] // Display weekday number as name (e.g. 1 to Mo)
                }
                TextInput {
                    id: endHourEdit
                    width: (parent.width - 100) / 4
                    text: endHour
                }
                Button {
                    width: beginWeekdayEdit.height; height: beginWeekdayEdit.height
                    text: "-"

                    onClicked: pausesModel.remove(index);
                }
            }
        }

        // New Pause
        Button {
            width: 150; height: 25
            anchors.right: parent.right
            anchors.rightMargin: 25
            text: "Ausnahme hinzufügen"

            onClicked: pausesModel.append({ beginWeekday: "", beginHour: "", endWeekday: "", endHour: "" });
        }
    }

// === Delete Server ===
    Button {
        id: deleteServerButton
        anchors.bottom: parent.bottom
        text: "Server löschen"
        width: 120; height: 25

        onClicked: {
            deleteServerButton.visible = false;
            confirmServerDeleteRow.visible = true;
        }
    }

    Row {
        id: confirmServerDeleteRow
        anchors.bottom: parent.bottom
        spacing: 10
        visible: false

        Button {
            text: "Abbrechen"
            width: 100; height: 25

            onClicked: {
                deleteServerButton.visible = true;
                confirmServerDeleteRow.visible = false;
            }
        }
        Button {
            text: "Bestätigen"
            width: 100; height: 25

            onClicked: {
                deleteServerButton.visible = true;
                confirmServerDeleteRow.visible = false;
                $.ajax("api.php/servers/" + serverModel.get(openServer).serverId, {
                    type: "DELETE",
                    success: function(data) {
                        reloadServerList();
                    }
                });
            }
        }
    }

// === Rules Editor ===
    Column {
        width: 500
        anchors.right: parent.right
        spacing: 5

        // Header
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            text: "<b>Regeln</b>\nReguläre Ausdrücke können in Schrägstrichen eingeschlossen verwendet werden.\n(Bsp.: \"/error(^\.txt)/i\" (ohne Anführungsstriche))"
        }

        ListModel {
            id: rulesModel
            ListElement { rule: "hallo" }
        }

        // Rules List
        Repeater {
            id: rulesRepeater
            model: rulesModel

            delegate: Item {
                width: parent.width
                height: 25
                TextInput {
                    id: editRuleEdit
                    width: parent.width - 30
                    text: rule
                }
                Button {
                    width: editRuleEdit.height; height: editRuleEdit.height
                    anchors.right: parent.right
                    text: "-"

                    onClicked: rulesModel.remove(index);
                }
            }
        }

        // New Rule
        Button {
            width: 150; height: 25
            anchors.right: parent.right
            text: "Regel hinzufügen"

            onClicked: rulesModel.append({ rule: "" });
        }
    }

// === Apply/Cancel Buttons ===
    Row {
        anchors { right: parent.right; bottom: parent.bottom }
        spacing: 5

        Button {
            id: cancelEdit
            width: 120; height: 25
            text: "Abbrechen"

            onClicked: closed();
        }
        Button {
            id: editRulesSubmit
            width: 120; height: 25
            text: "Anwenden"

            onClicked: applyChanges();
        }
    }
}