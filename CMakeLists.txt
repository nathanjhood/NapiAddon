# This file represents a cmake-js CMake API user's typical use-case scnario
# for illustrative purposes
cmake_minimum_required (VERSION 3.12...3.28 FATAL_ERROR)

# Add the path to 'CMakeJS.cmake' to this project's module path
list (APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

# include 'CMakeJS.cmake'. This can go before *or* after 'project()', since
# we are not depending on the PROJECT_* vars to be defined :)
include (CMakeJS)

project (demo VERSION 1.0.0)

#[===============[
# SIMPLE EXAMPLE:
#]===============]

# can name the target anything... best practice:
# make sure namespaces, directory/file pathnames,
# and names of targets are matching.

cmakejs_create_napi_addon (
  # NAME
  addon
  # SOURCES
  src/demo/addon.cpp
)

# And that's all you need to build a Napi Addon!


#[================[
# EXTENDED EXAMPLE:
#]================]

# it is possible to create as many addons as one wishes; here, an example of
# the proposed API's extended possibilities and functions... just to check that
# it all works as intended.

cmakejs_create_napi_addon (addon_v7
  # defines NAPI_VERSION. If not set, defaults to 8.
  NAPI_VERSION 7
  # defines NAPI_CPP_CUSTOM_NAMESPACE. If not set, the addon target name is used instead.
  NAMESPACE v7
  # defines 'CMAKEJS_ADDON_ALIAS' for an alias target name. If not set, 'NAPI_CPP_CUSTOM_NAMESPACE' is used instead.
  ALIAS addon::v7
)

cmakejs_napi_addon_add_sources (addon_v7
  # Specify an exact directory for this addon's SOURCES
  BASE_DIRS "${PROJECT_SOURCE_DIR}/src/demo"
  src/demo/addon.cpp
)

cmakejs_napi_addon_add_definitions (addon_v7
  # 'PRIVATE', 'PUBLIC', and 'INTERFACE' definitions are all supported.
  PRIVATE
  # See '<Napi.h>' for the default exceptions policy handling. Can be specified here.
  NAPI_CPP_EXCEPTIONS_MAYBE
)

#[=======================[
# BACKWARDS COMPATIBILITY:
#]=======================]

add_library(addon_v6 SHARED src/demo/addon.cpp)
set_target_properties(addon_v6 PROPERTIES PREFIX "" SUFFIX ".node")
target_link_libraries(addon_v6 cmake-js::addon-base)
# The above is enough to build an addon manually, thanks to the 'cmake-js::addon-base' link line!

#[===================[
# TESTING AND PACKING:
#]===================]

# Plenty of room left here for builders to explore CPack, CTest, and 'export()'
# their Addon target(s) as conventional CMake packages... the below example
# shows how to do that for a Napi Addon, and has been moved into it's own file,
# to keep the API example clean and seperate.
list (APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/share/cmake/Modules")

if(TRUE)
  # include(CTest) # If you want to see all the test dashboard targets, uncomment this include()
  enable_testing()
  include("${PROJECT_SOURCE_DIR}/test/tests.cmake")
  include(ExportNapiAddon)
endif()

# It's just worth checking that CPack, CTest, and 'export()' are working as they
# should and our API is not throwing any nasty errors :)
