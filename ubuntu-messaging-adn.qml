import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import "components"

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"
    
    // Note! applicationName needs to match the .desktop filename
    applicationName: "ubuntu-messaging-adn"
    
    /* 
     This property enables the application to change orientation 
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true
    
    width: units.gu(60)
    height: units.gu(80)

    property string apiDomain: "https://alpha-api.app.net/stream/0/"

    PageStack {
        id:pageStack
        Component.onCompleted: push(channelsView)

        Page {
            id: channelsView
            visible: false
            title: i18n.tr("Inbox")

            ListView {
                anchors.fill: parent

                JSONListModel {
                    id: channels
                    source: apiDomain + "channels?access_token=xyz"
                    query: "$.data[*]"
                }
                model: channels.model

                delegate: ListItem.Subtitled {
                    id: channelId
                    text: model.owner.username
                    subText: model.has_unread === true ? "**Unread messages" : ""  //TODO: replace this with unread style
                    icon: Qt.resolvedUrl(model.owner.avatar_image.url)
                    progression: true
                    onClicked: {
                        channelView.channelId = model.id
                        channelView.channelTitle = model.owner.username
                        pageStack.push(channelView)
                        // we currently always just go to most recent message, so update stream marker to that
                        // TODO: use stream markers properly
                        updateStreamMarker(model.id, model.recent_message_id)
                        channelId.subText = ""; //remove unread messages subText
                    }
                }
            }
        }

        Page {
            id: channelView
            visible: false
            title: i18n.tr(channelTitle)

            property string channelId: ""
            property string channelTitle: ""

            Column {
                anchors.fill: parent
                anchors.topMargin: units.gu(6)
                spacing: units.gu(6)
                ListView {
                    id: messageList

                    height: parent.height - messageText.height - sendMessage.height
                    width: parent.width
                    verticalLayoutDirection: ListView.BottomToTop

                    JSONListModel {
                        id: channel
                        source: apiDomain + "channels/" + channelView.channelId + "/messages?access_token=xyz"
                        query: "$.data[*]"
                    }
                    model: channel.model

                    delegate: ListItem.Subtitled {
                        id: messageId
                        property date createdDate: model.created_at
                        text: model.user.username + ", " + prettyDate(createdDate)
                        subText: model.html
                        icon: Qt.resolvedUrl(model.user.avatar_image.url)
                    }
                }

                Row {
                    spacing: units.gu(1)
                    TextArea {
                         id: messageText
                         placeholderText: "Enter message.."
                     }
                     Button {
                         id: sendMessage
                         text: "Send"
                         onClicked: {
                             postMessage(channelView.channelId, messageText.text)
                         }
                     }
                }

            }

        }
    }

    // Takes a date and returns a string representing how long ago the date represents.
    // TODO months and years
    function prettyDate(date){
        var seconds_diff = ((new Date() - date) / 1000),
            day_diff = Math.floor(seconds_diff / 86400);

        if (isNaN(day_diff) || day_diff < 0)
            return;

        return day_diff == 0 &&
            (
                seconds_diff < 60 && "just now" ||
                seconds_diff < 3600 && Math.floor(seconds_diff / 60) + "m" ||
                seconds_diff < 86400 && Math.floor(seconds_diff / 3600) + "h"
            ) ||
            day_diff < 14 && day_diff + "d" ||
            Math.ceil(day_diff / 7) + "w";
    }

    function postMessage(channelId, message) {
        var url = apiDomain + "channels/" + channelId + "/messages?access_token=xyz";
        var data = {text: message}
        var xhr = new XMLHttpRequest();

        xhr.open("POST", url);
        xhr.setRequestHeader("Content-type", "application/json");
        xhr.setRequestHeader("Connection", "close");

        xhr.onreadystatechange = function() {
            if (xhr.readyState == XMLHttpRequest.DONE) {
                var jsonResponse = JSON.parse(xhr.responseText)
                console.log(xhr.responseText)
                channel.model.insert(0, jsonResponse.data)
                messageText.text = "";
            }
        }
        xhr.send(JSON.stringify(data));
    }

    function updateStreamMarker(channelId, messageId) {
        var url = apiDomain + "posts/marker?access_token=xyz";
        var streamName = "channel:" + channelId
        var data = {name: streamName, id: messageId}
        var xhr = new XMLHttpRequest();

        xhr.open("POST", url);
        xhr.setRequestHeader("Content-type", "application/json");
        xhr.setRequestHeader("Connection", "close");

        xhr.onreadystatechange = function() {
            if (xhr.readyState == XMLHttpRequest.DONE) {
                var jsonResponse = JSON.parse(xhr.responseText)
                console.log(xhr.responseText)
            }
        }
        xhr.send(JSON.stringify(data));
    }
}
