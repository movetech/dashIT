/*
 * Copyright (C) 2013 movetech Systemberatung <info@movetech.net>
 * Copyright (C) 2013 Anton Kreuzkamp <akreuzkamp@web.de>
 *
 * This program is licensed under the terms of the GNU General Public License
 * version 3 or above. See LICENSE.txt.
 */

import QtQuick 1.1

Item {
    css.pointerEvents: "auto" // needed to receive clicks

    property bool loading: false
    property variant beforeShowDay: (function() {})

    signal selected(variant date)
    signal changedMonthYear(int year, int month)

    function refresh() {
        $(dom).datepicker("refresh");
    }
    function setDate(date) {
        $(dom).datepicker("setDate", date);
    }

    Component.onCompleted: {
        // Create datepicker
        var datepicker = $(dom).datepicker({
            dateFormat: 'yyyy/mm/dd',
            firstDay: 1,
            onSelect: function() {
                selected($(this).datepicker('getDate'));
            },
            onChangeMonthYear: function(year, month, inst) {
                changedMonthYear(year, month);
            },
            beforeShowDay: beforeShowDay
        });
        datepicker.show();
        $(dom.children[1]).css({ fontSize: 14 });

        // Set this Item's size to fit the datepicker
        implicitWidth = $(dom.children[1]).outerWidth();
        implicitHeight = $(dom.children[1]).outerHeight();
    }

    // Loading Indicator
    Image {
        id: loadingMonthImage
        width: 24; height: 24
        anchors.centerIn: parent
        source: "../style/loading.gif"
        opacity: loading ? 1 : 0

        Behavior on opacity { // Animate each change of the opacity
            NumberAnimation { duration: 250 }
        }
    }
}