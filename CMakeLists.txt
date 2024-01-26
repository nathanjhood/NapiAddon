# This file represents a cmake-js CMake API user's typical use-case scnario
# for illustrative purposes

cmake_minimum_required (VERSION 3.12...3.28 FATAL_ERROR)

# Add the path to 'CMakeJS.cmake' to this project's module path

list (APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

# include 'CMakeJS.cmake'. This can go before *or* after 'project()', since
# we are not depending on the PROJECT_* vars to be defined :)

include (CMakeJS)

project (demo VERSION 1.0.0)

# can name the target anything... best practice:
# make sure namespaces, directory/file pathnames,
# and names of targets are matching.

cmakejs_create_napi_addon (addon
  # SOURCES
  src/demo/addon.cpp
)


# it is possible to create as many addons as one wishes; here, an example of
# the proposed API's extended possibilities and functions...

cmakejs_create_napi_addon (addon_v7
  NAPI_VERSION 7
  NAMESPACE v7
)

cmakejs_napi_addon_add_sources (addon_v7
  # SOURCES
  src/demo/addon.cpp
)

cmakejs_napi_addon_add_definitions (addon_v7
  PRIVATE
  NAPI_CPP_EXCEPTIONS_MAYBE
)

# Plenty of room left here for builders to explore CPack, CTest, and 'export()'
# their Addon target(s) as conventional CMake packages... :)

# copy the types
file(COPY
  "${CMAKE_CURRENT_SOURCE_DIR}/lib/addon.node.js"
  "${CMAKE_CURRENT_SOURCE_DIR}/lib/addon.node.ts"
  "${CMAKE_CURRENT_SOURCE_DIR}/lib/addon.node.d.ts"
  DESTINATION
  "${CMAKE_CURRENT_BINARY_DIR}/lib"
)

# Here, the builder exports their addon as a CMake package:

list(APPEND TARGETS addon cmake-js-base)

# Collect and export targets
set (${PROJECT_NAME}_TARGETS "${TARGETS}" CACHE STRING "Targets to be built." FORCE)

# Export targets to binary dir
export (
  TARGETS ${${PROJECT_NAME}_TARGETS}
  FILE ${PROJECT_BINARY_DIR}/share/cmake/${PROJECT_NAME}_targets.cmake
  NAMESPACE ${PROJECT_NAME}::
)

# get access to helper functions for creating config files
list (APPEND CMAKE_MODULE_PATH
	"${CMAKE_CURRENT_LIST_DIR}/share/cmake/Modules"
)
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
set(CPACK_PACKAGE_NAME "${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}") # Compiled binary distribution
set(CPACK_SOURCE_PACKAGE_FILE_NAME "${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}-Source") # No system spec as this is un-compiled source file distribution
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${PROJECT_DESCRIPTION})
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_VERSION_PATCH})
set(CPACK_PACKAGE_VERSION_TWEAK ${PROJECT_VERSION_VERSION_TWEAK})
set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_CURRENT_LIST_DIR}/LICENSE)
set(CPACK_RESOURCE_FILE_README ${CMAKE_CURRENT_LIST_DIR}/README.md)
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)
set(CPACK_COMPONENT_INCLUDE_TOPLEVEL_DIRECTORY OFF)
set(CPACK_SOURCE_GENERATOR "TGZ;ZIP")
set(CPACK_SOURCE_IGNORE_FILES
    _CPack_Packages
    /*.zip
    /*.tar
    /*.tar.*
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
