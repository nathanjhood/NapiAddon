cmake_minimum_required(VERSION 3.28)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

project (demo)

include(NapiAddon)

add_napi_addon(addon
  # SOURCES
  src/demo/addon.cpp
)
