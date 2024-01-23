cmake_minimum_required(VERSION 3.28)

# Add the path to 'CMakeJS.cmake' to the module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

project (demo)

# include 'CMakeJS.cmake'
include(CMakeJS)

# can name the addon anything...
cmakejs_create_napi_addon(addon
  # SOURCES
  src/demo/addon.cpp
)
