add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_org.kde.latte.containment\")
configure_file(metadata.desktop.cmake ${CMAKE_CURRENT_SOURCE_DIR}/package/metadata.desktop)

plasma_install_package(package org.kde.latte.containment)

set(containment_SRCS
    plugin/lattetypes.h
    plugin/types.cpp
    plugin/layoutmanager.cpp
    plugin/lattecontainmentplugin.cpp
)

add_library(lattecontainmentplugin SHARED ${containment_SRCS})

target_link_libraries(lattecontainmentplugin
                      Qt5::Core
                      Qt5::Qml
                      Qt5::Quick
                      KF5::Declarative
                      KF5::Plasma)

install(TARGETS lattecontainmentplugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/latte/private/containment)
install(FILES plugin/qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/latte/private/containment)
