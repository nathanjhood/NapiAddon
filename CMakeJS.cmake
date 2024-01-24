#[=============================================================================[
  Check whether we have already been included (borrowed from CMakeRC)
]=============================================================================]#
# Hypothetical version number...
set(_version 8.0.0)

cmake_minimum_required(VERSION 3.12)
include(CMakeParseArguments)

if(COMMAND cmakejs_napi_addon_add_sources)
  if(NOT DEFINED _CMAKEJS_VERSION OR NOT (_version STREQUAL _CMAKEJS_VERSION))
      message(WARNING "More than one CMakeJS version has been included in this project.")
  endif()
  # CMakeJS has already been included! Don't do anything
  return()
endif()

set(_CMAKEJS_VERSION "${_version}" CACHE INTERNAL "CMakeJS version. Used for checking for conflicts")

set(_CMAKEJS_SCRIPT "${CMAKE_CURRENT_LIST_FILE}" CACHE INTERNAL "Path to 'CMakeJS.cmake' script")

if(NOT DEFINED CMAKEJS_BINARY_DIR)
  set(CMAKEJS_BINARY_DIR "${CMAKE_BINARY_DIR}")
endif()

#[=============================================================================[
Provides ```NODE_EXECUTABLE``` for executing NodeJS commands in CMake scripts.
]=============================================================================]#
function(cmakejs_acquire_node_executable)
  find_program(NODE_EXECUTABLE
    NAMES "node" "node.exe"
    PATHS "$ENV{PATH}" "$ENV{ProgramFiles}/nodejs"
    DOC "NodeJs executable binary"
    REQUIRED
  )

  if(VERBOSE)
    message(STATUS "NODE_EXECUTABLE: ${NODE_EXECUTABLE}")
  endif()

endfunction()

if(NOT DEFINED NODE_EXECUTABLE)
  cmakejs_acquire_node_executable()
  message(STATUS "NODE_EXECUTABLE: ${NODE_EXECUTABLE}")
endif()

#[=============================================================================[
Provides ```NODE_API_HEADERS_DIR``` for NodeJS C Addon development files.
]=============================================================================]#
function(cmakejs_acquire_napi_c_files)
  execute_process(
    COMMAND "${NODE_EXECUTABLE}" -p "require('node-api-headers').include_dir"
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE NODE_API_HEADERS_DIR
    COMMAND_ERROR_IS_FATAL ANY
  )
  string(REGEX REPLACE "[\r\n\"]" "" NODE_API_HEADERS_DIR ${NODE_API_HEADERS_DIR})
  set(NODE_API_HEADERS_DIR "${NODE_API_HEADERS_DIR}" CACHE PATH "Node API Headers directory." FORCE)

  file(GLOB NODE_API_INC_FILES "${NODE_API_HEADERS_DIR}/*.h")
  source_group("Node Addon API (C)" FILES ${NODE_API_INC_FILES})

  if(VERBOSE)
    message(STATUS "NODE_API_HEADERS_DIR: ${NODE_API_HEADERS_DIR}")
  endif()

endfunction()

if(NOT DEFINED NODE_API_HEADERS_DIR)
  cmakejs_acquire_napi_c_files()
  message(STATUS "NODE_API_HEADERS_DIR: ${NODE_API_HEADERS_DIR}")
endif()

#[=============================================================================[
Provides ```NODE_ADDON_API_DIR``` for NodeJS C++ Addon development files.
]=============================================================================]#
function(cmakejs_acquire_napi_cpp_files)

  execute_process(
    COMMAND "${NODE_EXECUTABLE}" -p "require('node-addon-api').include"
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE NODE_ADDON_API_DIR
    COMMAND_ERROR_IS_FATAL ANY
  )
  string(REGEX REPLACE "[\r\n\"]" "" NODE_ADDON_API_DIR ${NODE_ADDON_API_DIR})
  set(NODE_ADDON_API_DIR "${NODE_ADDON_API_DIR}" CACHE PATH "Node Addon API Headers directory." FORCE)

  file(GLOB NODE_ADDON_API_INC_FILES "${NODE_ADDON_API_DIR}/*.h")
  source_group("Node Addon API (C++)" FILES ${NODE_ADDON_API_INC_FILES})

  if(VERBOSE)
    message(STATUS "NODE_ADDON_API_DIR: ${NODE_ADDON_API_DIR}")
  endif()

endfunction()

if(NOT DEFINED NODE_ADDON_API_DIR)
  cmakejs_acquire_napi_cpp_files()
  message(STATUS "NODE_ADDON_API_DIR: ${NODE_ADDON_API_DIR}")
endif()

#[=============================================================================[
  Create an interface library (no output) with all Addon API dependencies for
  linkage.
]=============================================================================]#
add_library (cmake-js-base INTERFACE)
add_library (cmake-js::base ALIAS cmake-js-base)
target_include_directories (cmake-js-base INTERFACE ${CMAKE_JS_INC} ${NODE_API_HEADERS_DIR} ${NODE_ADDON_API_DIR})
target_sources (cmake-js-base INTERFACE ${CMAKE_JS_SRC})
target_link_libraries (cmake-js-base ${CMAKE_JS_LIB})
if (MSVC AND CMAKE_JS_NODELIB_DEF AND CMAKE_JS_NODELIB_TARGET)
  execute_process (COMMAND ${CMAKE_AR} /def:${CMAKE_JS_NODELIB_DEF} /out:${CMAKE_JS_NODELIB_TARGET} ${CMAKE_STATIC_LINKER_FLAGS})
endif ()

#[=============================================================================[
Internal helper (borrowed from CMakeRC).
]=============================================================================]#
function(_cmakejs_normalize_path var)
  set(path "${${var}}")
  file(TO_CMAKE_PATH "${path}" path)
  while(path MATCHES "//")
      string(REPLACE "//" "/" path "${path}")
  endwhile()
  string(REGEX REPLACE "/+$" "" path "${path}")
  set("${var}" "${path}" PARENT_SCOPE)
endfunction()

#[=============================================================================[
  Export a helper function for creating a dynamic ```*.node``` library, linked
  to the Addon API interface.
]=============================================================================]#
function(cmakejs_create_napi_addon name)

  set(args ALIAS NAMESPACE NAPI_VERSION)
  cmake_parse_arguments(ARG "" "${args}" "" "${ARGN}")

  # Generate the identifier for the resource library's namespace
  set(ns_re "[a-zA-Z_][a-zA-Z0-9_]*")

  if(NOT DEFINED ARG_NAMESPACE)
    # Check that the library name is also a valid namespace
    if(NOT name MATCHES "${ns_re}")
      message(SEND_ERROR "Library name is not a valid namespace. Specify the NAMESPACE argument")
    endif()
    set(ARG_NAMESPACE "${name}")
  else()
    if(NOT ARG_NAMESPACE MATCHES "${ns_re}")
      message(SEND_ERROR "NAMESPACE for ${name} is not a valid C++ namespace identifier (${ARG_NAMESPACE})")
    endif()
  endif()

  # Needs more validation...
  if(DEFINED ARG_NAPI_VERSION AND (ARG_NAPI_VERSION LESS_EQUAL 0))
    message(SEND_ERROR "NAPI_VERSION for ${name} is not a valid Integer number (${ARG_NAPI_VERSION})")
  endif()

  if(NOT DEFINED ARG_NAPI_VERSION)
    if(NOT DEFINED NAPI_VERSION)
      set(NAPI_VERSION 8)
    endif()
    set(ARG_NAPI_VERSION ${NAPI_VERSION})
  endif()

  if(ARG_ALIAS)
    set(name_alt "${ARG_ALIAS}")
  else()
    set(name_alt "${ARG_NAMESPACE}::${name}")
  endif()

  if(VERBOSE)
    message(STATUS "Configuring Napi Addon: ${name}")
  endif()

  add_library(${name} SHARED)
  add_library("${name_alt}" ALIAS ${name})

  target_link_libraries(${name} cmake-js::base)

  target_compile_definitions(${name}
    PRIVATE
    "CMAKEJS_ADDON_NAME=${name}"
    "NAPI_CPP_CUSTOM_NAMESPACE=${ARG_NAMESPACE}"
    "NAPI_VERSION=${ARG_NAPI_VERSION}"
  )

  target_include_directories(${name}
    PUBLIC
    $<BUILD_INTERFACE:${CMAKEJS_BINARY_DIR}/include/${PROJECT_NAME}>
    $<INSTALL_INTERFACE:include/${PROJECT_NAME}>
  )

  set_property(
    TARGET ${name}
    PROPERTY ${name}_IS_NAPI_ADDON_LIBRARY TRUE
  )

  set_target_properties(${name}
    PROPERTIES

    LIBRARY_OUTPUT_NAME "${name}"
    LIBRARY_OUTPUT_NAME_DEBUG "d${name}"
    PREFIX ""
    SUFFIX ".node"

    ARCHIVE_OUTPUT_DIRECTORY "${CMAKEJS_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKEJS_BINARY_DIR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKEJS_BINARY_DIR}/bin"

    ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKEJS_BINARY_DIR}/lib/Debug"
    LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKEJS_BINARY_DIR}/lib/Debug"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKEJS_BINARY_DIR}/bin/Debug"
  )

  cmakejs_napi_addon_add_sources(${name} ${ARG_UNPARSED_ARGUMENTS})

endfunction()

#[=============================================================================[
Add source files to an existing Napi Addon target.
]=============================================================================]#
function(cmakejs_napi_addon_add_sources name)

  get_target_property(is_addon_lib ${name} ${name}_IS_NAPI_ADDON_LIBRARY)
  if(NOT TARGET ${name} OR NOT is_addon_lib)
    message(SEND_ERROR "'cmakejs_napi_addon_add_sources()' called on target '${name}' which is not an existing napi addon library")
    return()
  endif()

  set(options)
  set(args BASE_DIRS)
  set(list_args)
  cmake_parse_arguments(ARG "${options}" "${args}" "${list_args}" "${ARGN}")

  if(NOT ARG_BASE_DIRS)
    set(ARG_BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR})
  endif()
  _cmakejs_normalize_path(ARG_BASE_DIRS)
  get_filename_component(ARG_BASE_DIRS "${ARG_BASE_DIRS}" ABSOLUTE)

  # Generate the identifier for the resource library's namespace
  get_target_property(lib_namespace "${name}" ${name}_ADDON_NAMESPACE)

  foreach(input IN LISTS ARG_UNPARSED_ARGUMENTS)

    _cmakejs_normalize_path(input)
    get_filename_component(abs_in "${input}" ABSOLUTE)
    file(RELATIVE_PATH relpath "${ARG_BASE_DIRS}" "${abs_in}")
    if(relpath MATCHES "^\\.\\.")
      # For now we just error on files that exist outside of the soure dir.
      message(SEND_ERROR "Cannot add file '${input}': File must be in a subdirectory of ${ARG_BASE_DIRS}")
      continue()
    endif()

    target_sources(${name} PRIVATE "${abs_in}")

  endforeach()

endfunction()
