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

import QtQuick 2.1
import QtQuick.Window 2.2

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

import org.kde.latte.core 0.2 as LatteCore
import org.kde.latte.private.containment 0.1 as LatteContainment

Item{
    id: manager

    anchors.fill: parent

    property QtObject window

    property bool blockUpdateMask: false
    property bool inForceHiding: false //is used when the docks are forced in hiding e.g. when changing layouts
    property bool normalState : false  // this is being set from updateMaskArea
    property bool previousNormalState : false // this is only for debugging purposes
    property bool panelIsBiggerFromIconSize: root.useThemePanel && (background.totals.visualThickness >= (metrics.iconSize + metrics.margin.thickness))

    property bool maskIsFloating: !root.behaveAsPlasmaPanel
                                  && screenEdgeMarginEnabled
                                  && !root.floatingInternalGapIsForced
                                  && !inSlidingIn
                                  && !inSlidingOut

    property int maskFloatedGap: maskIsFloating ? Math.max(0, metrics.margin.screenEdge - background.shadows.headThickness) : 0

    property int animationSpeed: LatteCore.WindowSystem.compositingActive ?
                                     (root.editMode ? 400 : animations.speedFactor.normal * 1.62 * animations.duration.large) : 0



    property bool inLocationAnimation: latteView && latteView.positioner && latteView.positioner.inLocationAnimation
    property bool inSlidingIn: false //necessary because of its init structure
    property alias inSlidingOut: slidingAnimationAutoHiddenOut.running
    property bool inRelocationHiding: false
    property bool inScreenEdgeInternalWindowSliding: root.behaveAsDockWithMask && hideThickScreenGap

    readonly property bool inSliding: inSlidingIn || inSlidingOut || inRelocationHiding || inScreenEdgeInternalWindowSliding || inLocationAnimation
    readonly property bool isSinkedEventEnabled: !(parabolic.isEnabled && (animations.needBothAxis.count>0 || animations.needLength.count>0))
                                                 && !inSlidingIn
                                                 && !inSlidingOut
                                                 && !latteView.visibility.isHidden

    property int length: root.isVertical ?  Screen.height : Screen.width   //screenGeometry.height : screenGeometry.width

    property int slidingOutToPos: {
        if (root.behaveAsPlasmaPanel) {
            var edgeMargin = screenEdgeMarginEnabled ? plasmoid.configuration.screenEdgeMargin : 0

            root.isHorizontal ? root.height + edgeMargin - 1 : root.width + edgeMargin - 1;
        } else {
            var topOrLeftEdge = ((plasmoid.location===PlasmaCore.Types.LeftEdge)||(plasmoid.location===PlasmaCore.Types.TopEdge));
            return (topOrLeftEdge ? -metrics.mask.thickness.normal : metrics.mask.thickness.normal);
        }
    }

    //! when Latte behaves as Plasma panel
    property int thicknessAsPanel: metrics.totals.thickness


    property Item applets: null

    Binding{
        target: latteView
        property:"maxThickness"
        //! prevents updating window geometry during closing window in wayland and such fixes a crash
        when: latteView && !inRelocationHiding && !inForceHiding && !inScreenEdgeInternalWindowSliding
        value: root.behaveAsPlasmaPanel ? thicknessAsPanel : metrics.mask.thickness.maxZoomed
    }

    property bool validIconSize: (metrics.iconSize===metrics.maxIconSize || metrics.iconSize === autosize.iconSize)
    property bool inPublishingState: validIconSize && !inSlidingIn && !inSlidingOut && !inRelocationHiding && !inForceHiding

    Binding{
        target: latteView
        property:"normalThickness"
        when: latteView && inPublishingState
        value: root.behaveAsPlasmaPanel ? thicknessAsPanel : metrics.mask.thickness.maxNormalForItems
    }

    Binding{
        target: latteView
        property:"normalHighestThickness"
        when: latteView && inPublishingState
        value: metrics.mask.thickness.maxNormal
    }

    Binding {
        target: latteView
        property: "headThicknessGap"
        when: latteView && !inRelocationHiding && !inForceHiding && !inScreenEdgeInternalWindowSliding && inPublishingState
        value: {
            if (root.behaveAsPlasmaPanel || root.viewType === LatteCore.Types.PanelView || latteView.byPassWM) {
                return 0;
            }

            return metrics.mask.thickness.maxZoomed - metrics.mask.thickness.maxNormal + metrics.extraThicknessForNormal;
        }
    }

    Binding{
        target: latteView
        property: "type"
        when: latteView
        value: root.viewType
    }

    Binding{
        target: latteView
        property: "behaveAsPlasmaPanel"
        when: latteView
        value: root.behaveAsPlasmaPanel
    }

    Binding{
        target: latteView
        property: "fontPixelSize"
        when: theme
        value: theme.defaultFont.pixelSize
    }

    Binding{
        target: latteView
        property: "maxLength"
        when: latteView
        value: maxLengthPerCentage/100
    }

    Binding{
        target: latteView
        property: "offset"
        when: latteView
        value: plasmoid.configuration.offset/100
    }

    Binding{
        target: latteView
        property: "screenEdgeMargin"
        when: latteView
        value: plasmoid.configuration.shrinkThickMargins ? 0 :Math.max(0, plasmoid.configuration.screenEdgeMargin)
    }

    Binding{
        target: latteView
        property: "screenEdgeMarginEnabled"
        when: latteView
        value: root.screenEdgeMarginEnabled && !root.hideThickScreenGap
    }

    Binding{
        target: latteView
        property: "alignment"
        when: latteView
        value: root.panelAlignment
    }

    Binding{
        target: latteView
        property: "isTouchingTopViewAndIsBusy"
        when: root.viewIsAvailable
        value: {
            if (!root.viewIsAvailable) {
                return false;
            }

            var isTouchingTopScreenEdge = (latteView.y === latteView.screenGeometry.y);
            var isStickedOnTopBorder = (plasmoid.configuration.alignment === LatteCore.Types.Justify && plasmoid.configuration.maxLength===100)
                    || (plasmoid.configuration.alignment === LatteCore.Types.Top && plasmoid.configuration.offset===0);

            return root.isVertical && !latteView.visibility.isHidden && !isTouchingTopScreenEdge && isStickedOnTopBorder && background.isShown;
        }
    }

    Binding{
        target: latteView
        property: "isTouchingBottomViewAndIsBusy"
        when: latteView
        value: {
            if (!root.viewIsAvailable) {
                return false;
            }

            var latteBottom = latteView.y + latteView.height;
            var screenBottom = latteView.screenGeometry.y + latteView.screenGeometry.height;
            var isTouchingBottomScreenEdge = (latteBottom === screenBottom);

            var isStickedOnBottomBorder = (plasmoid.configuration.alignment === LatteCore.Types.Justify && plasmoid.configuration.maxLength===100)
                    || (plasmoid.configuration.alignment === LatteCore.Types.Bottom && plasmoid.configuration.offset===0);

            return root.isVertical && !latteView.visibility.isHidden && !isTouchingBottomScreenEdge && isStickedOnBottomBorder && background.isShown;
        }
    }

    Binding{
        target: latteView
        property: "colorizer"
        when: latteView
        value: colorizerManager
    }

    //! View::Effects bindings
    Binding{
        target: latteView && latteView.effects ? latteView.effects : null
        property: "backgroundAllCorners"
        when: latteView && latteView.effects
        value: plasmoid.configuration.backgroundAllCorners
               && (!root.screenEdgeMarginEnabled /*no-floating*/
                   || (root.screenEdgeMarginEnabled /*floating with justify alignment and 100% maxlength*/
                       && plasmoid.configuration.maxLength===100
                       && root.panelAlignment===LatteCore.Types.Justify
                       && !root.hideLengthScreenGaps))
    }

    Binding{
        target: latteView && latteView.effects ? latteView.effects : null
        property: "backgroundRadius"
        when: latteView && latteView.effects
        value: background.customRadius
    }

    Binding{
        target: latteView && latteView.effects ? latteView.effects : null
        property: "backgroundRadiusEnabled"
        when: latteView && latteView.effects
        value: background.customRadiusIsEnabled
    }

    Binding{
        target: latteView && latteView.effects ? latteView.effects : null
        property: "backgroundOpacity"
        when: latteView && latteView.effects
        value: themeExtended.useCustomColors ? 0 : background.currentOpacity
    }

    Binding{
        target: latteView && latteView.effects ? latteView.effects : null
        property: "drawEffects"
        when: latteView && latteView.effects
        value: LatteCore.WindowSystem.compositingActive
               && (((root.blurEnabled && root.useThemePanel)
                    || (root.blurEnabled && root.forceSolidPanel && LatteCore.WindowSystem.compositingActive))
                   && (!root.inStartup || inForceHiding || inRelocationHiding))
    }

    Binding{
        target: latteView && latteView.effects ? latteView.effects : null
        property: "drawShadows"
        when: latteView && latteView.effects
        value: root.drawShadowsExternal && (!root.inStartup || inForceHiding || inRelocationHiding) && !(latteView && latteView.visibility.isHidden)
    }

    Binding{
        target: latteView && latteView.effects ? latteView.effects : null
        property:"editShadow"
        when: latteView && latteView.effects
        value: root.editShadow
    }

    Binding{
        target: latteView && latteView.effects ? latteView.effects : null
        property:"innerShadow"
        when: latteView && latteView.effects
        value: background.shadows.headThickness
    }

    //! View::Positioner bindings
    Binding{
        target: latteView && latteView.positioner ? latteView.positioner : null
        property: "isStickedOnTopEdge"
        when: latteView && latteView.positioner
        value: plasmoid.configuration.isStickedOnTopEdge
    }

    Binding{
        target: latteView && latteView.positioner ? latteView.positioner : null
        property: "isStickedOnBottomEdge"
        when: latteView && latteView.positioner
        value: plasmoid.configuration.isStickedOnBottomEdge
    }

    //! View::WindowsTracker bindings
    Binding{
        target: latteView && latteView.windowsTracker ? latteView.windowsTracker : null
        property: "enabled"
        when: latteView && latteView.windowsTracker && latteView.visibility
        value: (latteView && latteView.visibility
                && !(latteView.visibility.mode === LatteCore.Types.AlwaysVisible /* Visibility */
                     || latteView.visibility.mode === LatteCore.Types.WindowsGoBelow
                     || latteView.visibility.mode === LatteCore.Types.AutoHide))
               || applets.require.windowsTrackingCount > 0                   /*Applets Need Windows Tracking */
               || root.dragActiveWindowEnabled                               /*Dragging Active Window(Empty Areas)*/
               || ((root.backgroundOnlyOnMaximized                           /*Dynamic Background */
                    || plasmoid.configuration.solidBackgroundForMaximized
                    || root.disablePanelShadowMaximized
                    || root.windowColors !== LatteContainment.Types.NoneWindowColors))
               || (root.screenEdgeMarginsEnabled                             /*Dynamic Screen Edge Margin*/
                   && plasmoid.configuration.hideFloatingGapForMaximized)
    }

    Connections{
        target: background.totals
        onVisualLengthChanged: updateMaskArea();
        onVisualThicknessChanged: updateMaskArea();
    }

    Connections{
        target: background.shadows
        onHeadThicknessChanged: updateMaskArea();
    }

    Connections{
        target: latteView ? latteView : null
        onXChanged: updateMaskArea();
        onYChanged: updateMaskArea()
        onWidthChanged: updateMaskArea();
        onHeightChanged: updateMaskArea();
    }

    Connections{
        target: animations.needBothAxis
        onCountChanged: updateMaskArea();
    }

    Connections{
        target: animations.needLength
        onCountChanged: updateMaskArea();
    }

    Connections{
        target: animations.needThickness
        onCountChanged: updateMaskArea();
    }

    Connections{
        target: layoutsManager
        onCurrentLayoutIsSwitching: {
            if (LatteCore.WindowSystem.compositingActive && latteView && latteView.layout && latteView.layout.name === layoutName) {
                parabolic.sglClearZoom();
            }
        }
    }

    Connections {
        target: metrics.mask.thickness
        onMaxZoomedChanged: updateMaskArea()
    }

    Connections{
        target: themeExtended ? themeExtended : null
        onThemeChanged: latteView.effects.forceMaskRedraw();
    }

    onMaskIsFloatingChanged: updateMaskArea();

    onNormalStateChanged: {
        if (normalState) {
            autosize.updateIconSize();
            layouter.updateSizeForAppletsInFill();
        }
    }

    function slotContainsMouseChanged() {
        if(latteView.visibility.containsMouse && latteView.visibility.mode !== LatteCore.Types.SidebarOnDemand) {
            updateMaskArea();

            if (slidingAnimationAutoHiddenOut.running && !inRelocationHiding && !inForceHiding) {
                slotMustBeShown();
            }
        }
    }

    function slotMustBeShown() {
        //! WindowsCanCover case
        if (latteView && latteView.visibility.mode === LatteCore.Types.WindowsCanCover) {
            latteView.visibility.setViewOnFrontLayer();
            return;
        }

        if (!latteView.visibility.isHidden && latteView.positioner.inSlideAnimation) {
            // Do not update when Positioner mid-slide animation takes place, for example:
            // 1. Latte panel is hiding its floating gap for maximized window
            // 2. the user clicks on an applet popup.
            // 3. Applet popups showing/hiding are triggering hidingIsBlockedChanged() signals.
            // 4. hidingIsBlockedChanged() signals create mustBeShown events when visibility::hidingIsBlocked() is not enabled.
            return;
        }

        //! Normal Dodge/AutoHide case
        if (!slidingAnimationAutoHiddenIn.running && !inRelocationHiding && !inForceHiding){
            slidingAnimationAutoHiddenIn.init();
        }
    }

    function slotMustBeHide() {
        if (inSlidingIn && !inRelocationHiding) {
            /*consider hiding after sliding in has finished*/
            return;
        }

        if (latteView && latteView.visibility.mode === LatteCore.Types.WindowsCanCover) {
            latteView.visibility.setViewOnBackLayer();
            return;
        }

        //! prevent sliding-in on startup if the dodge modes have sent a hide signal
        if (inStartupTimer.running && root.inStartup) {
            root.inStartup = false;
        }

        //! Normal Dodge/AutoHide case
        if((!slidingAnimationAutoHiddenOut.running
            && !latteView.visibility.blockHiding
            && (!latteView.visibility.containsMouse || latteView.visibility.mode === LatteCore.Types.SidebarOnDemand))
                || inForceHiding) {
            slidingAnimationAutoHiddenOut.init();
        }
    }

    //! functions used for sliding out/in during location/screen changes
    function slotHideDockDuringLocationChange() {
        inRelocationHiding = true;
        blockUpdateMask = true;

        if(!slidingAnimationAutoHiddenOut.running) {
            slidingAnimationAutoHiddenOut.init();
        }
    }

    function slotShowDockAfterLocationChange() {
        slidingAnimationAutoHiddenIn.init();
    }

    function sendHideDockDuringLocationChangeFinished(){
        blockUpdateMask = false;
        latteView.positioner.hideDockDuringLocationChangeFinished();
    }

    function sendSlidingOutAnimationEnded() {
        latteView.visibility.hide();
        latteView.visibility.isHidden = true;

        if (debug.maskEnabled) {
            console.log("hiding animation ended...");
        }

        sendHideDockDuringLocationChangeFinished();
    }

    ///test maskArea
    function updateMaskArea() {
        if (!latteView || !root.viewIsAvailable || blockUpdateMask) {
            return;
        }

        var localX = 0;
        var localY = 0;

        normalState = ((animations.needBothAxis.count === 0) && (animations.needLength.count === 0))
                || (latteView && latteView.visibility.isHidden && !latteView.visibility.containsMouse && animations.needThickness.count === 0);


        // debug maskArea criteria
        if (debug.maskEnabled) {
            console.log(animations.needBothAxis.count + ", " + animations.needLength.count + ", " +
                        animations.needThickness.count + ", " + latteView.visibility.isHidden);

            if (previousNormalState !== normalState) {
                console.log("normal state changed to:" + normalState);
                previousNormalState = normalState;
            }
        }

        //console.log("reached updating geometry ::: "+dock.maskArea);


        if (inPublishingState && !latteView.visibility.isHidden && normalState) {
            //! Important: Local Geometry must not be updated when view ISHIDDEN
            //! because it breaks Dodge(s) modes in such case

            var localGeometry = Qt.rect(0, 0, root.width, root.height);

            //the shadows size must be removed from the maskArea
            //before updating the localDockGeometry
            if (!latteView.behaveAsPlasmaPanel) {
                var cleanThickness = metrics.totals.thickness;
                var edgeMargin = metrics.mask.screenEdge;

                if (plasmoid.location === PlasmaCore.Types.TopEdge) {
                    localGeometry.x = latteView.effects.rect.x; // from effects area
                    localGeometry.width = latteView.effects.rect.width; // from effects area

                    localGeometry.y = edgeMargin;
                    localGeometry.height = cleanThickness;
                } else if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
                    localGeometry.x = latteView.effects.rect.x; // from effects area
                    localGeometry.width = latteView.effects.rect.width; // from effects area

                    localGeometry.y = root.height - cleanThickness - edgeMargin;
                    localGeometry.height = cleanThickness;
                } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
                    localGeometry.y = latteView.effects.rect.y; // from effects area
                    localGeometry.height = latteView.effects.rect.height; // from effects area

                    localGeometry.x = edgeMargin;
                    localGeometry.width = cleanThickness;
                } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
                    localGeometry.y = latteView.effects.rect.y; // from effects area
                    localGeometry.height = latteView.effects.rect.height; // from effects area

                    localGeometry.x = root.width - cleanThickness - edgeMargin;
                    localGeometry.width = cleanThickness;
                }

                //set the boundaries for latteView local geometry
                //qBound = qMax(min, qMin(value, max)).

                localGeometry.x = Math.max(0, Math.min(localGeometry.x, latteView.width));
                localGeometry.y = Math.max(0, Math.min(localGeometry.y, latteView.height));
                localGeometry.width = Math.min(localGeometry.width, latteView.width);
                localGeometry.height = Math.min(localGeometry.height, latteView.height);
            }

            //console.log("update geometry ::: "+localGeometry);
            latteView.localGeometry = localGeometry;
        }

        //! Input Mask
        var animated = (animations.needBothAxis.count>0);

        if (!LatteCore.WindowSystem.compositingActive || animated || latteView.behaveAsPlasmaPanel) {
            latteView.effects.inputMask = Qt.rect(0, 0, -1, -1);
        } else {
            var inputThickness = latteView.visibility.isHidden ? metrics.mask.thickness.hidden : metrics.mask.screenEdge + metrics.totals.thickness;
            var inputGeometry = Qt.rect(0, 0, root.width, root.height);

            if (plasmoid.location === PlasmaCore.Types.TopEdge) {
                inputGeometry.x = latteView.effects.rect.x; // from effects area
                inputGeometry.y = 0;

                inputGeometry.width = latteView.effects.rect.width; // from effects area
                inputGeometry.height = inputThickness ;
            } else if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
                inputGeometry.x = latteView.effects.rect.x; // from effects area
                inputGeometry.y = root.height - inputThickness;

                inputGeometry.width = latteView.effects.rect.width; // from effects area
                inputGeometry.height = inputThickness;
            } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
                inputGeometry.x = 0;
                inputGeometry.y = latteView.effects.rect.y; // from effects area

                inputGeometry.width = inputThickness;
                inputGeometry.height = latteView.effects.rect.height; // from effects area
            } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
                inputGeometry.x = root.width - inputThickness;
                inputGeometry.y = latteView.effects.rect.y; // from effects area

                inputGeometry.width = inputThickness;
                inputGeometry.height = latteView.effects.rect.height; // from effects area
            }

            //set the boundaries for latteView local geometry
            //qBound = qMax(min, qMin(value, max)).

            inputGeometry.x = Math.max(0, Math.min(inputGeometry.x, latteView.width));
            inputGeometry.y = Math.max(0, Math.min(inputGeometry.y, latteView.height));
            inputGeometry.width = Math.min(inputGeometry.width, latteView.width);
            inputGeometry.height = Math.min(inputGeometry.height, latteView.height);

            latteView.effects.inputMask = inputGeometry;
        }
    }

    Loader{
        anchors.fill: parent
        active: debug.graphicsEnabled

        sourceComponent: Item{
            anchors.fill:parent

            Rectangle{
                id: windowBackground
                anchors.fill: parent
                border.color: "red"
                border.width: 1
                color: "transparent"
            }

            Rectangle{
                x: latteView ? latteView.effects.mask.x : -1
                y: latteView ? latteView.effects.mask.y : -1
                height: latteView ? latteView.effects.mask.height : 0
                width: latteView ? latteView.effects.mask.width : 0

                border.color: "green"
                border.width: 1
                color: "transparent"
            }
        }
    }

    /***Hiding/Showing Animations*****/

    //////////////// Animations - Slide In - Out
    SequentialAnimation{
        id: slidingAnimationAutoHiddenOut

        ScriptAction{
            script: {
                root.isHalfShown = true;
            }
        }

        PropertyAnimation {
            target: !root.behaveAsPlasmaPanel ? layoutsContainer : latteView.positioner
            property: !root.behaveAsPlasmaPanel ? (root.isVertical ? "x" : "y") : "slideOffset"
            to: {
                if (root.behaveAsPlasmaPanel) {
                    return slidingOutToPos;
                }

                if (LatteCore.WindowSystem.compositingActive) {
                    return slidingOutToPos;
                } else {
                    if ((plasmoid.location===PlasmaCore.Types.LeftEdge)||(plasmoid.location===PlasmaCore.Types.TopEdge)) {
                        return slidingOutToPos + 1;
                    } else {
                        return slidingOutToPos - 1;
                    }
                }
            }
            duration: manager.animationSpeed
            easing.type: Easing.InQuad
        }

        ScriptAction{
            script: {
                latteView.visibility.isHidden = true;

                if (root.behaveAsPlasmaPanel && latteView.positioner.slideOffset !== 0) {
                    //! hide real panels when they slide-out
                    latteView.visibility.hide();
                }
            }
        }

        onStarted: {
            if (debug.maskEnabled) {
                console.log("hiding animation started...");
            }
        }

        onStopped: {
            //! Trying to move the ending part of the signals at the end of editing animation
            if (!manager.inRelocationHiding) {
                manager.updateMaskArea();
            } else {
                if (!root.editMode) {
                    manager.sendSlidingOutAnimationEnded();
                }
            }

            latteView.visibility.slideOutFinished();
        }

        function init() {
            if (manager.inLocationAnimation || !latteView.visibility.blockHiding) {
                start();
            }
        }
    }

    SequentialAnimation{
        id: slidingAnimationAutoHiddenIn

        PauseAnimation{
            duration: manager.inRelocationHiding && animations.active ? 500 : 0
        }

        PropertyAnimation {
            target: !root.behaveAsPlasmaPanel ? layoutsContainer : latteView.positioner
            property: !root.behaveAsPlasmaPanel ? (root.isVertical ? "x" : "y") : "slideOffset"
            to: 0
            duration: manager.animationSpeed
            easing.type: Easing.OutQuad
        }

        ScriptAction{
            script: {
                root.isHalfShown = false;
                root.inStartup = false;
            }
        }

        onStarted: {
            latteView.visibility.show();

            if (debug.maskEnabled) {
                console.log("showing animation started...");
            }
        }

        onStopped: {
            inSlidingIn = false;

            if (manager.inRelocationHiding) {
                manager.inRelocationHiding = false;
                autosize.updateIconSize();
            }

            manager.inRelocationHiding = false;
            autosize.updateIconSize();

            if (debug.maskEnabled) {
                console.log("showing animation ended...");
            }

            latteView.visibility.slideInFinished();

            //! this is needed in order to update dock absolute geometry correctly in the end AND
            //! when a floating dock is sliding-in through masking techniques
            updateMaskArea();
        }

        function init() {
            if (!root.viewIsAvailable) {
                return;
            }

            inSlidingIn = true;

            if (slidingAnimationAutoHiddenOut.running) {
                slidingAnimationAutoHiddenOut.stop();
            }

            latteView.visibility.isHidden = false;
            updateMaskArea();

            start();
        }
    }

    //! Slides Animations for FLOATING+BEHAVEASPLASMAPANEL when
    //! HIDETHICKSCREENCAP dynamically is enabled/disabled
    SequentialAnimation{
        id: slidingInRealFloating

        PropertyAnimation {
            target: latteView ? latteView.positioner : null
            property: "slideOffset"
            to: 0
            duration: manager.animationSpeed
            easing.type: Easing.OutQuad
        }

        ScriptAction{
            script: {
                latteView.positioner.inSlideAnimation = false;
            }
        }

        onStopped: latteView.positioner.inSlideAnimation = false;

    }

    SequentialAnimation{
        id: slidingOutRealFloating

        ScriptAction{
            script: {
                latteView.positioner.inSlideAnimation = true;
            }
        }

        PropertyAnimation {
            target: latteView ? latteView.positioner : null
            property: "slideOffset"
            to: plasmoid.configuration.screenEdgeMargin
            duration: manager.animationSpeed
            easing.type: Easing.InQuad
        }
    }

    Connections {
        target: root
        onHideThickScreenGapChanged: {
            if (!latteView || !root.viewIsAvailable) {
                return;
            }

            if (root.behaveAsPlasmaPanel && !latteView.visibility.isHidden && !inSlidingIn && !inSlidingOut && !inStartup) {
                slideInOutRealFloating();
            }
        }

        onInStartupChanged: {
            //! used for positioning properly real floating panels when there is a maximized window
            if (root.hideThickScreenGap && !inStartup && latteView.positioner.slideOffset===0) {
                if (root.behaveAsPlasmaPanel && !latteView.visibility.isHidden) {
                    slideInOutRealFloating();
                }
            }
        }

        function slideInOutRealFloating() {
            if (root.hideThickScreenGap) {
                slidingInRealFloating.stop();
                slidingOutRealFloating.start();
            } else {
                slidingOutRealFloating.stop();
                slidingInRealFloating.start();
            }
        }
    }


}
