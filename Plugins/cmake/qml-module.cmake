function(vast_module arg_TARGET)
    cmake_parse_arguments(
        PARSE_ARGV 1 arg
        ""
        "URI"
        "SOURCES;QML_FILES;QML_SINGLETONS;DEPENDENCIES;IMPORTS;OPTIONAL_IMPORTS;DEFAULT_IMPORTS;LIBRARIES"
    )

    set_source_files_properties(${arg_QML_SINGLETONS} PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

    qt_add_library(${arg_TARGET} SHARED)
    qt_add_qml_module(${arg_TARGET}
        URI ${arg_URI}
        SOURCES ${arg_SOURCES}
        QML_FILES ${arg_QML_FILES} ${arg_QML_SINGLETONS}
        DEPENDENCIES ${arg_DEPENDENCIES}
        IMPORTS ${arg_IMPORTS}
        OPTIONAL_IMPORTS ${arg_OPTIONAL_IMPORTS}
        DEFAULT_IMPORTS ${arg_DEFAULT_IMPORTS}
    )

    qt_query_qml_module(${arg_TARGET}
        URI module_uri
        PLUGIN_TARGET module_plugin_target
        TARGET_PATH module_target_path
        QMLDIR module_qmldir
        TYPEINFO module_typeinfo
    )
    message(STATUS "Created QML module: ${module_uri}")

    # Install backing targets to <ns>/lib so different modules can find and
    # link each other; plugin targets stay in their own module directories.
    string(REPLACE "/" ";" uri_parts "${module_target_path}")
    list(GET uri_parts 0 top_level)
    set(backing_lib_dir "${INSTALL_QMLDIR}/${top_level}/lib")
    set(module_dir "${INSTALL_QMLDIR}/${module_target_path}")

    install(TARGETS ${arg_TARGET}
        LIBRARY DESTINATION "${backing_lib_dir}"
        RUNTIME DESTINATION "${backing_lib_dir}"
    )

    install(TARGETS "${module_plugin_target}"
        LIBRARY DESTINATION "${module_dir}"
        RUNTIME DESTINATION "${module_dir}"
    )

    install(FILES "${module_qmldir}" DESTINATION "${module_dir}")
    install(FILES "${module_typeinfo}" DESTINATION "${module_dir}")

    # Resolve intra-module angle-bracket includes (<ClipboardModel.hpp>, ...)
    target_include_directories(${arg_TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

    target_link_libraries(${arg_TARGET} PRIVATE
        Qt::Core
        Qt::Gui
        Qt::Qml
        Qt::Quick
        ${arg_LIBRARIES}
    )

    # Add the backing lib dir to the plugin rpath so it can find its backing target
    file(RELATIVE_PATH plugin_to_lib "/${module_target_path}" "/${top_level}/lib")
    set_property(TARGET "${module_plugin_target}" APPEND PROPERTY INSTALL_RPATH "$ORIGIN/${plugin_to_lib}")

    # Backing targets all land in <ns>/lib and may link each other (e.g.
    # Vast.Clipboard -> Vast core), so resolve siblings from their own dir.
    set_property(TARGET ${arg_TARGET} APPEND PROPERTY INSTALL_RPATH "$ORIGIN")
endfunction()
