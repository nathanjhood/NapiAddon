cmake_minimum_required(VERSION 3.12...3.28 FATAL_ERROR)

# Add the path to 'CMakeJS.cmake' to this project's module path

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

# include 'CMakeJS.cmake'. This can go before *or* after 'project()', since
# we are not depending on the PROJECT_* vars to be defined :)

include(CMakeJS)

project (demo)

# can name the target anything... best practice:
# make sure namespaces, directory/file pathnames,
# and names of targets are matching.

cmakejs_create_napi_addon(addon
  # SOURCES
  src/demo/addon.cpp
)


# it is possible to create as many addons as one wishes;
# as an example of the API's extended possibilities and functions, here, along
# with some more args.

cmakejs_create_napi_addon(addon_v7
  NAPI_VERSION 7
  NAMESPACE v7
)

cmakejs_napi_addon_add_sources(addon_v7
  # SOURCES
  src/demo/addon.cpp
)

# Plenty of room left here for builders to explore CPack, CTest, and 'export()'
# their Addon target(s) as conventional CMake packages... :)
