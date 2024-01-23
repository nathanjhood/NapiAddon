cmake_minimum_required(VERSION 3.28)

# Add the path to 'CMakeJS.cmake' to the module path
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

# some more args as an example of the API's possibilities
cmakejs_create_napi_addon(addon_v7
  # SOURCES
  src/demo/addon.cpp
  NAPI_VERSION 7
  NAMESPACE v7
)
