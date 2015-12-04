/*
 * Copyright (c) 2013, Stefan Brand <seiichiro@seiichiro0185.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this 
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this
 *    list of conditions and the following disclaimer in the documentation and/or other 
 *    materials provided with the distribution.
 * 
 * 3. The names of the contributors may not be used to endorse or promote products 
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../lib/crypto.js" as OTP
import "../lib/storage.js" as DB

// Define the Layout of the Active Cover
CoverBackground {
  id: coverPage

  property double lastUpdated: 0

  function updateOTP() {
    // get seconds from current Date
    var curDate = new Date();
    var type;

    if (lOTP.text == "------" || curDate.getSeconds() == 30 || curDate.getSeconds() == 0 || (curDate.getTime() - lastUpdated > 2000)) {
     if (appWin.coverTitle.substr(0,6) == "Steam:") {
       type = "TOTP_STEAM"
     } else {
       type = "TOTP"
     }
      appWin.coverOTP = OTP.calcOTP(appWin.coverSecret, type, 0);
    }

    // Change color of the OTP to red if less than 5 seconds left
    if (29 - (curDate.getSeconds() % 30) < 5) {
      lOTP.color = "red"
    } else {
      lOTP.color = Theme.highlightColor
    }

    lastUpdated = curDate.getTime();
  }

  Timer {
    interval: 1000
    // Timer runs only when cover is visible and favourite is set
    running: !Qt.application.active && appWin.coverSecret != "" && appWin.coverType == "TOTP"
    repeat: true
    onTriggered: updateOTP();
  }

  // Show the SailOTP Logo
  Image {
    id: logo
    source: "../sailotp.png"
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 48
  }

  Column {
    anchors.top: logo.bottom
    width: parent.width
    anchors.topMargin: 48
    anchors.horizontalCenter: parent.horizontalCenter

    Label {
      text: appWin.coverTitle
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width - Theme.paddingMedium*2
      maximumLineCount: 1
      truncationMode: TruncationMode.Fade
      horizontalAlignment: contentWidth <= width ? Text.AlignHCenter : Text.AlignLeft
    }
    Label {
      id: lOTP
      text: appWin.coverOTP
      anchors.horizontalCenter: parent.horizontalCenter
      color: Theme.highlightColor
      font.pixelSize: Theme.fontSizeExtraLarge
    }
  }
  // CoverAction to update a HOTP-Token, only visible for HOTP-Type Tokens
  CoverActionList {
    CoverAction {
      iconSource: appWin.coverType == "HOTP" ? "image://theme/icon-cover-refresh" : "image://theme/icon-cover-previous"
      onTriggered: {
        if (appWin.coverType == "HOTP") {
          appWin.coverOTP = OTP.calcOTP(appWin.coverSecret, "HOTP", DB.getCounter(appWin.coverTitle, appWin.coverSecret, true));
        } else {
          var index = appWin.coverIndex - 1
          if (index < 0) index = appWin.listModel.count - 1
          appWin.setCover(index);
          DB.setFav(appWin.coverTitle, appWin.coverSecret)
          if (appWin.coverType == "TOTP") updateOTP();
        }
      }
    }
    CoverAction {
      iconSource: "image://theme/icon-cover-next"
      onTriggered: {
        var index = appWin.coverIndex + 1
        if (index >= appWin.listModel.count) index = 0
        appWin.setCover(index);
        DB.setFav(appWin.coverTitle, appWin.coverSecret)
        if (appWin.coverType == "TOTP") updateOTP();
      }
    }
  }
}
