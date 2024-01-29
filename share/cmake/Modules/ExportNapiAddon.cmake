# Here, the builder exports their addon as a CMake package:

# copy the types
file(COPY
  "${PROJECT_SOURCE_DIR}/lib/addon.node.js"
  "${PROJECT_SOURCE_DIR}/lib/addon.node.ts"
  "${PROJECT_SOURCE_DIR}/lib/addon.node.d.ts"
  DESTINATION
  "${PROJECT_BINARY_DIR}/lib"
)

# Make a list of targets to export (cmake-js-base is resolved)
list(APPEND TARGETS addon addon_v7)

# Collect and export targets
set (${PROJECT_NAME}_TARGETS "${TARGETS}" CACHE STRING "Targets to be built." FORCE)

# Export targets to binary dir
export (
  TARGETS ${${PROJECT_NAME}_TARGETS}
  FILE ${PROJECT_BINARY_DIR}/share/cmake/${PROJECT_NAME}_targets.cmake
  NAMESPACE ${PROJECT_NAME}::
)

# get access to helper functions for creating config files
include (CMakePackageConfigHelpers)
include (JoinPaths)
join_paths (libdir_for_pc_file     "\${exec_prefix}" "${CMAKE_INSTALL_LIBDIR}")
join_paths (includedir_for_pc_file "\${prefix}"      "${CMAKE_INSTALL_INCLUDEDIR}")

# Create package config file
configure_file (
  ${PROJECT_SOURCE_DIR}/share/pkgconfig/${PROJECT_NAME}.pc.in
  ${PROJECT_BINARY_DIR}/share/pkgconfig/${PROJECT_NAME}.pc
  @ONLY
)

# create cmake config file
configure_package_config_file (
    ${PROJECT_SOURCE_DIR}/share/cmake/${PROJECT_NAME}_config.cmake.in
    ${PROJECT_BINARY_DIR}/share/cmake/${PROJECT_NAME}_config.cmake
  INSTALL_DESTINATION
    ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

# generate the version file for the cmake config file
write_basic_package_version_file (
	${PROJECT_BINARY_DIR}/share/cmake/${PROJECT_NAME}_config_version.cmake
	VERSION ${PROJECT_VERSION}
	COMPATIBILITY AnyNewerVersion
)


#[===[.md

Configure CPack.

#]===]
# set(CPACK_PACKAGE_CHECKSUM "${PROJECT_VERSION_TWEAK}")
# set(CPACK_PACKAGE_VENDOR "StoneyDSP")
set(CPACK_PACKAGE_NAME              "${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
set(CPACK_PACKAGE_FILE_NAME         "${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}") # Compiled binary distribution
set(CPACK_SOURCE_PACKAGE_FILE_NAME  "${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}-Source") # No system spec as this is un-compiled source file distribution
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${PROJECT_DESCRIPTION})
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_VERSION_PATCH})
set(CPACK_PACKAGE_VERSION_TWEAK ${PROJECT_VERSION_VERSION_TWEAK})
set(CPACK_RESOURCE_FILE_LICENSE ${PROJECT_SOURCE_DIR}/LICENSE)
set(CPACK_RESOURCE_FILE_README  ${PROJECT_SOURCE_DIR}/README.md)
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)
set(CPACK_COMPONENT_INCLUDE_TOPLEVEL_DIRECTORY OFF)
set(CPACK_SOURCE_GENERATOR "TGZ;ZIP")
set(CPACK_SOURCE_IGNORE_FILES
    _CPack_Packages
    /*.zip
    /*.tar
    /*.tar.*
    /.env*
    /.git/*
    /.cmake
    /.github
    /.vs
    /.vscode
    /.cache
    /.config
    /.local
    /doc
    /docs
    /bin
    /lib
    /usr
    /out
    /build
    /Release
    /Debug
    /MinSizeRel
    /RelWithDebInfo
    /downloads
    /installed
    /node_modules
    /vcpkg
    /.*build.*
    /package-lock.json
    /yarn.lock
    /\\\\.DS_Store
)
include(CPack)
