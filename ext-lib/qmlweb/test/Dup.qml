Rectangle {
    id: page
    width: 500; height: 500
    color: "lightgray"

    Repeater {
        id: rep
        model: 0

        delegate: Rectangle {
            x: 5 + (width + 10) * (index %2)
            y: 5 + 100 * Math.floor(index /2)
            width: page.width / 2 - 10
            height: 90
            border.color: "darkgrey"
            color: "orange"

            Text {
                anchors.centerIn: parent
                text: "Element " + index + "/" + rep.count

                Component.onCompleted: console.log("Added an element (index: " + index + ")");
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        onClicked: rep.model = 8;
    }
}
