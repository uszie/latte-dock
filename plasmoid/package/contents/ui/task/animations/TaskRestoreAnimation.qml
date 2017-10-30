/*
*  Copyright 2016  Smith AR <audoban@openmailbox.org>
*                  Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of Latte-Dock
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0

import org.kde.plasma.plasmoid 2.0

///////Restore Zoom Animation/////
ParallelAnimation{
    id: restoreAnimation

    PropertyAnimation {
        target: wrapper
        property: "mScale"
        to: 1
        duration: 3 * mainItemContainer.animationTime
        easing.type: Easing.Linear
    }

    PropertyAnimation {
        target: hiddenSpacerLeft
        property: "nScale"
        to: 0
        duration: 3 * mainItemContainer.animationTime
        easing.type: Easing.Linear
    }

    PropertyAnimation {
        target: hiddenSpacerRight
        property: "nScale"
        to: 0
        duration: 3 * mainItemContainer.animationTime
        easing.type: Easing.Linear
    }

    onStarted: {
        // console.log("restore animation started...");
    }
}
