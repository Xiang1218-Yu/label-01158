cmake_minimum_required(VERSION 3.16)
project(campus_nav_gui)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0")

find_package(Qt6 COMPONENTS Widgets REQUIRED)

add_executable(campus_nav_gui
    src/main.cpp
    src/mainwindow.cpp
    src/mapwidget.cpp
    src/graph.cpp
    src/campus_data.cpp
    include/mainwindow.h
    include/mapwidget.h
    resources/resources.qrc
)

target_include_directories(campus_nav_gui PRIVATE
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(campus_nav_gui PRIVATE Qt6::Widgets)

if(APPLE)
    set_target_properties(campus_nav_gui PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER com.campusnav.gui
        MACOSX_BUNDLE_BUNDLE_NAME "Campus Nav GUI"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0.0"
        MACOSX_BUNDLE_BUNDLE_VERSION "1.0.0"
    )
endif()

if(WIN32)
    set_target_properties(campus_nav_gui PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()

install(TARGETS campus_nav_gui
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION .
)

if(APPLE)
    install(DIRECTORY ${CMAKE_BINARY_DIR}/campus_nav_gui.app
            DESTINATION .
            USE_SOURCE_PERMISSIONS
            OPTIONAL
    )
endif()
