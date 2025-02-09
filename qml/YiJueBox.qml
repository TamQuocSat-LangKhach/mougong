import QtQuick
import QtQuick.Layouts
import Fk.RoomElement

ColumnLayout {
  id: root
  anchors.fill: parent
  property var extra_data: ({ name: "", data: [] })
  signal finish()

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: luatr(extra_data.name)
  }

  Text {
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    font.pixelSize: 18
    color: "#E4D5A0"
    text: extra_data.data.map(seat => luatr('seat#' + seat)).join('、')

    wrapMode: Text.WordWrap
    textFormat: Text.RichText
  }
  
}

