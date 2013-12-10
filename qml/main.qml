/*
 * Copyright (C) 2013 movetech Systemberatung <info@movetech.net>
 * Copyright (C) 2013 Anton Kreuzkamp <akreuzkamp@web.de>
 *
 * This program is licensed under the terms of the GNU General Public License
 * version 3 or above. See LICENSE.txt.
 */

import QtQuick 1.1

Item {
    id: root
    anchors.fill: parent // Fill the whole page (parent is document.body)

    /**
     * The currently open server. Open means the server that the server shows
     * the details view or is open for editing. -1 means, no server is open at
     * the present.
     */
    property int openServer: -1

    /**
     * The datetime of the last run of the worker script.
     */
    property string lastUpdate

    Timer {
        interval: 60000 * refreshInterval
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: reloadServerList();
    }

    /**
     * Files an AJAX-request to the server asking for a list of servers and
     * refreshes the server list according to the response.
     * Used to initally load the server list, as well as for updating it after
     * a change.
     */
    function reloadServerList() {
        console.log("Doing refresh!");
        loadingServersImage.visible = true;
        detailsView.visible = false;
        detailsView.parent = root;
        openServer = -1;
        $.ajax("api.php/servers", { success: function(dataString) {
            serverModel.clear();
            data = JSON.parse(dataString);
            if (data.error) {
                alert("Ein Fehler ist aufgetreten. Der Server meldet:\n" + data.error);
                loadingServersImage.visible = false;
                return;
            }

            lastUpdate = data.lastUpdate;
            for (var i in data.serverList) {
                if (data.serverList[i].history[0].bad === "1")
                    serverModel.insert(0, data.serverList[i]);
                else
                    serverModel.append(data.serverList[i]);
            }
            loadingServersImage.visible = false;
        }});
    }

    // Loading Indicator
    Image {
        id: loadingServersImage
        width: 24; height: 24
        anchors.centerIn: parent
        source: "../style/loading.gif"
        z: 2
    }

// === Server List ===
    ListModel {
        id: serverModel
    }

    ServerList {
        id: serverList
        anchors { fill: parent; margins: 50 }
    }

// === Details View ===
    // This item is the details view that is used for all servers together.
    // It will be dynamically positioned inside the respective server item,
    // by changing the parent of this view to the server item.
    DetailsView {
        id: detailsView
        anchors { fill: parent; margins: 10; topMargin: 40 }
        visible: false
    }

// === Server Editor ===
    // This item is the editing view that is used for all servers together.
    // It will be dynamically positioned inside the respective server item,
    // by changing the parent of this editor to the server item.
    ServerEditor {
        id: serverEditor
        anchors { fill: parent; margins: 10; topMargin: 40; rightMargin: 30 }
        visible: false
    }

// === Last Update Label ===
    Text {
        anchors { bottom: parent.bottom; left: parent.left; margins: 5 }
        text: "Copyright © 2013-2014 <a href=\"http://www.movetech.net\">movetech Systemberatung</a>"
    }

// === Last Update Label ===
    Text {
        anchors { bottom: parent.bottom; right: parent.right; margins: 5 }
        text: "Letzter Abruf der Backup-Mails: " + lastUpdate
        visible: lastUpdate // hide if lastUpdate is empty
    }
}