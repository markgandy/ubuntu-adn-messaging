import QtQuick 2.0
import Ubuntu.Components.ListItems 0.1 as ListItem

ListItem.Subtitled {
    onClicked: Theme.name = "Ubuntu.Components.Themes.Ambiance"
    ColorAnimation { from: "white"; to: "black"; duration: 200 }
}
