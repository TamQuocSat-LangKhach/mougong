// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root

  property var selectedItem: []
  property var playerInfos: []
  property string titleName: ""

  title.text: Backend.translate(titleName)
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 700
  height: 360

  Flickable {
    anchors.fill: parent
    contentWidth: photoRow.width
    ScrollBar.horizontal: ScrollBar {}
    clip: true

    flickableDirection: Flickable.HorizontalFlick

    RowLayout {
      id: photoRow
      anchors.centerIn: parent
      spacing: 0

      Repeater {
        id: photoRepeater
        model: playerInfos

        Photo {
          playerid: modelData.id
          general: modelData.general
          deputyGeneral: modelData.deputyGeneral
          role: modelData.role
          state: "candidate"
          screenName: modelData.screenName
          kingdom: modelData.kingdom
          seatNumber: modelData.seat
          selectable: true

          Image {
            visible: selectedItem.some(data => data.id === modelData.id)
            source: SkinBank.CARD_DIR + "chosen"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 15
            scale: 2
          }

          onSelectedChanged: {
            selectedItem = [modelData];
          }

          Component.onCompleted: {
            this.visibleChildren[12].visible = false;
          }
        }
      }
    }
  }

  Item {
    id: buttonArea
    anchors.fill: parent
    anchors.bottomMargin: 10
    height: 40

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      spacing: 8

      MetroButton {
        Layout.fillWidth: true
        text: Backend.translate("OK")
        enabled: selectedItem.length

        onClicked: {
          close();
          roomScene.state = "notactive";
          const reply = JSON.stringify(
            {
              playerId: selectedItem[0].id
            }
          );
          ClientInstance.replyToServer("", reply);
        }
      }

      MetroButton {
        id: detailBtn
        enabled: selectedItem.length
        text: Backend.translate("Show General Detail")
        onClicked: {
          const { general, deputyGeneral } = selectedItem[0];
          const generals = [general];
          deputyGeneral && generals.push(deputyGeneral);

          roomScene.startCheat("GeneralDetail", { generals });
        }
      }
    }
  }

  function loadData(data) {
    playerInfos = data[0].map(playerId => {
      const player = leval(
        `(function()
          local player = ClientInstance:getPlayerById(${playerId})
          return {
            id = player.id,
            general = player.general,
            deputyGeneral = player.deputyGeneral,
            screenName = player.player:getScreenName(),
            kingdom = player.kingdom,
            seat = player.seat,
            role = 'hidden',
          }
        end)()`
      );
      return player;
    });
    titleName = data[1];
  }
}
