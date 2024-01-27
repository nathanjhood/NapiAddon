#[=============================================================================[
  Check whether we have already been included (borrowed from CMakeRC)
#]=============================================================================]
# Hypothetical CMakeJS version number...
set(_version 8.0.0)

cmake_minimum_required(VERSION 3.15)
cmake_policy(VERSION 3.15)
include(CMakeParseArguments)

if(COMMAND cmakejs_napi_addon_add_sources)
    if(NOT DEFINED _CMAKEJS_VERSION OR NOT (_version STREQUAL _CMAKEJS_VERSION))
        message(WARNING "More than one CMakeJS version has been included in this project.")
    endif()
    # CMakeJS has already been included! Don't do anything
    return()
endif()

set(_CMAKEJS_VERSION "${_version}" CACHE INTERNAL "CMakeJS version. Used for checking for conflicts")
unset(_version)

set(_CMAKEJS_SCRIPT "${CMAKE_CURRENT_LIST_FILE}" CACHE INTERNAL "Path to 'CMakeJS.cmake' script")

# Default build output directory, if not specified with '-DCMAKEJS_BINARY_DIR:PATH=/some/dir'
if(NOT DEFINED CMAKEJS_BINARY_DIR)
    set(CMAKEJS_BINARY_DIR "${CMAKE_BINARY_DIR}")
endif()

#[=============================================================================[
Internal helper (borrowed from CMakeRC).
#]=============================================================================]
function(_cmakejs_normalize_path var)
    set(path "${${var}}")
    file(TO_CMAKE_PATH "${path}" path)
    while(path MATCHES "//")
        string(REPLACE "//" "/" path "${path}")
    endwhile()
    string(REGEX REPLACE "/+$" "" path "${path}")
    set("${var}" "${path}" PARENT_SCOPE)
endfunction()

#[=======================================================================[
FindCMakeJs.cmake
--------

Find the native CMakeJs includes, source, and library

(This codeblock typically belongs in a file named 'FindCMakeJS.cmake' for
distribution...)

This module defines

::

  CMAKE_JS_INC, where to find node.h, etc.
  CMAKE_JS_LIB, the libraries required to use CMakeJs.
  CMAKE_JS_SRC, where to find required *.cpp files, if any

#]=======================================================================]

# CMAKE_JS_INC is defined on all platforms when calling from cmake-js.
# By checking whether this var is pre-defined, we can determine if we are
# running from an npm script (via cmake-js), or from CMake directly...

if (NOT DEFINED CMAKE_JS_INC)

    # ...and if we're calling from CMake directly, we need to set up some vars
    # that our build step depends on (these are predefined when calling via npm/cmake-js).
    if(VERBOSE)
        message(STATUS "CMake Calling...")
    endif()

    # Check for cmake-js installations
    find_program(CMAKE_JS_EXECUTABLE
      NAMES "cmake-js" "cmake-js.exe"
      PATHS "$ENV{PATH}" "$ENV{ProgramFiles}/cmake-js"
      DOC "cmake-js system executable binary"
      REQUIRED
    )
    if (NOT CMAKE_JS_EXECUTABLE)
        message(FATAL_ERROR "cmake-js system installation not found! Please run 'npm -g install cmake-js@latest' and try again.")
        return()
    endif()

    _cmakejs_normalize_path(CMAKE_JS_EXECUTABLE)
    string(REGEX REPLACE "[\r\n\"]" "" CMAKE_JS_EXECUTABLE "${CMAKE_JS_EXECUTABLE}")

    find_program(CMAKE_JS_NPM_PACKAGE
      NAMES "cmake-js" "cmake-js.exe"
      PATHS "${CMAKE_CURRENT_SOURCE_DIR}/node_modules/cmake-js/bin"
      DOC "cmake-js project-local npm package binary"
      REQUIRED
    )
    if (NOT CMAKE_JS_NPM_PACKAGE)
        message(FATAL_ERROR "cmake-js project-local npm package not found! Please run 'npm install' and try again.")
        return()
    endif()

    # Execute the CLI commands, and write their outputs into the cached vars
    # where the remaining build processes expect them to be...
    execute_process(
      COMMAND "${CMAKE_JS_EXECUTABLE}" "print-cmakejs-include" "--log-level error" "--generator ${CMAKE_GENERATOR}"
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      OUTPUT_VARIABLE CMAKE_JS_INC
    )

    execute_process(
      COMMAND "${CMAKE_JS_EXECUTABLE}" "print-cmakejs-src" "--log-level error" "--generator ${CMAKE_GENERATOR}"
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      OUTPUT_VARIABLE CMAKE_JS_SRC
    )

    execute_process(
      COMMAND "${CMAKE_JS_EXECUTABLE}" "print-cmakejs-lib" "--log-level error" "--generator ${CMAKE_GENERATOR}"
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      OUTPUT_VARIABLE CMAKE_JS_LIB
    )

    # Strip the vars of any unusual chars that might break the paths...
    _cmakejs_normalize_path(CMAKE_JS_INC)
    _cmakejs_normalize_path(CMAKE_JS_SRC)
    _cmakejs_normalize_path(CMAKE_JS_LIB)

    string(REGEX REPLACE "[\r\n\"]" "" CMAKE_JS_INC "${CMAKE_JS_INC}")
    string(REGEX REPLACE "[\r\n\"]" "" CMAKE_JS_SRC "${CMAKE_JS_SRC}")
    string(REGEX REPLACE "[\r\n\"]" "" CMAKE_JS_LIB "${CMAKE_JS_LIB}")

    set(CMAKE_JS_INC "${CMAKE_JS_INC}" CACHE STRING "cmake-js include directory." FORCE)
    set(CMAKE_JS_SRC "${CMAKE_JS_SRC}" CACHE STRING "cmake-js source file." FORCE)
    set(CMAKE_JS_LIB "${CMAKE_JS_LIB}" CACHE STRING "cmake-js lib file." FORCE)

    # At this point, some warnings may occur re: the below (still investigating);
    # Define either NAPI_CPP_EXCEPTIONS or NAPI_DISABLE_CPP_EXCEPTIONS.
    #set (NAPI_CPP_EXCEPTIONS TRUE CACHE STRING "Define either NAPI_CPP_EXCEPTIONS or NAPI_DISABLE_CPP_EXCEPTIONS")
    add_definitions(-DNAPI_CPP_EXCEPTIONS) # Also needs /EHsc
    # add_definitions(-DNAPI_DISABLE_CPP_EXCEPTIONS)

else ()

    # ... we already are calling via npm/cmake-js, so we should already have all the vars we need!
    if(VERBOSE)
        message(DEBUG "CMakeJS Calling...")
    endif()

endif ()

# Log the vars to the console for sanity...
if(VERBOSE)
    message(DEBUG "CMAKE_JS_INC = ${CMAKE_JS_INC}")
    message(DEBUG "CMAKE_JS_SRC = ${CMAKE_JS_SRC}")
    message(DEBUG "CMAKE_JS_LIB = ${CMAKE_JS_LIB}")
endif()

#[=============================================================================[
Provides NODE_EXECUTABLE for executing NodeJS commands in CMake scripts.
#]=============================================================================]
function(cmakejs_acquire_node_executable)
    find_program(NODE_EXECUTABLE
      NAMES "node" "node.exe"
      PATHS "$ENV{PATH}" "$ENV{ProgramFiles}/nodejs"
      DOC "NodeJs executable binary"
      REQUIRED
    )
    if (NOT NODE_EXECUTABLE)
        message(FATAL_ERROR "NodeJS installation not found! Please check your paths and try again.")
        return()
    endif()

    if(VERBOSE)
        message(STATUS "NODE_EXECUTABLE: ${NODE_EXECUTABLE}")
    endif()
endfunction()

if(NOT DEFINED NODE_EXECUTABLE)
    cmakejs_acquire_node_executable()
    message(STATUS "NODE_EXECUTABLE: ${NODE_EXECUTABLE}")
endif()

# Resolve NodeJS development headers
# TODO: This code block is quite problematic, since:
# 1 - it might trigger a build run, depending on how the builder has set up their package.json scripts...
# 2 - it also currently assumes a preference for yarn over npm (and the others)...
# 3 - finally, because of how cmake-js works, it might create Ninja-build artefacts,
# even when the CMake user specifies a different generator to CMake manually...
if(NOT IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/node_modules")
    execute_process(
      COMMAND yarn install
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      OUTPUT_VARIABLE NODE_MODULES_DIR
    )
    if(NOT IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/node_modules")
        message(FATAL_ERROR "Something went wrong - NodeJS modules installation failed!")
        return()
    endif()
endif()

#[=============================================================================[
Provides NODE_API_HEADERS_DIR for NodeJS C Addon development files.
#]=============================================================================]
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

# Acquire if needed...
if(NOT DEFINED NODE_API_HEADERS_DIR)
    cmakejs_acquire_napi_c_files()
    message(STATUS "NODE_API_HEADERS_DIR: ${NODE_API_HEADERS_DIR}")
endif()

#[=============================================================================[
Provides NODE_ADDON_API_DIR for NodeJS C++ Addon development files.
#]=============================================================================]
function(cmakejs_acquire_napi_cpp_files)
    execute_process(
      COMMAND "${NODE_EXECUTABLE}" -p "require('node-addon-api').include"
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      OUTPUT_VARIABLE NODE_ADDON_API_DIR
      COMMAND_ERROR_IS_FATAL ANY
    )
    string(REGEX REPLACE "[\r\n\"]" "" NODE_ADDON_API_DIR "${NODE_ADDON_API_DIR}")
    set(NODE_ADDON_API_DIR "${NODE_ADDON_API_DIR}" CACHE PATH "Node Addon API Headers directory." FORCE)

    file(GLOB NODE_ADDON_API_INC_FILES "${NODE_ADDON_API_DIR}/*.h")
    source_group("Node Addon API (C++)" FILES "${NODE_ADDON_API_INC_FILES}")

    if(VERBOSE)
        message(STATUS "NODE_ADDON_API_DIR: ${NODE_ADDON_API_DIR}")
    endif()
endfunction()

# Acquire if needed...
if(NOT DEFINED NODE_ADDON_API_DIR)
    cmakejs_acquire_napi_cpp_files()
    message(STATUS "NODE_ADDON_API_DIR: ${NODE_ADDON_API_DIR}")
endif()

#[=============================================================================[
Silently create an interface library (no output) with all Addon API dependencies
resolved, for Addon targets to link with.

(This should be expanded to contain most of cmake-js globally-required
configuration)
#]=============================================================================]
add_library                 (cmake-js-addon-base INTERFACE)
add_library                 (cmake-js::addon-base ALIAS cmake-js-addon-base)
target_include_directories  (cmake-js-addon-base INTERFACE "${CMAKE_JS_INC}" "${NODE_API_HEADERS_DIR}" "${NODE_ADDON_API_DIR}")
target_sources              (cmake-js-addon-base INTERFACE ${CMAKE_JS_SRC})
target_link_libraries       (cmake-js-addon-base INTERFACE "${CMAKE_JS_LIB}")
target_compile_definitions  (cmake-js-addon-base INTERFACE "BUILDING_NODE_EXTENSION")
# Signal a basic C++11 feature to require C++11.
target_compile_features     (cmake-js-addon-base INTERFACE cxx_nullptr)
if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>" CACHE STRING "Select the MSVC runtime library for use by compilers targeting the MSVC ABI." FORCE)
    if(CMAKE_JS_NODELIB_DEF AND CMAKE_JS_NODELIB_TARGET)
        execute_process(COMMAND ${CMAKE_AR} /def:${CMAKE_JS_NODELIB_DEF} /out:${CMAKE_JS_NODELIB_TARGET} ${CMAKE_STATIC_LINKER_FLAGS})
    endif()
endif()

#[=============================================================================[
Exposes a user-side helper function for creating a dynamic '*.node' library,
linked to the Addon API interface.

cmakejs_create_napi_addon(<name>)
cmakejs_create_napi_addon(<name> [ALIAS <alias>] [NAMESPACE <namespace>] [NAPI_VERSION <version>])

(This should wrap the CMakeLists.txt-side requirements for building a Napi Addon)
#]=============================================================================]
function(cmakejs_create_napi_addon name)

    # Avoid duplicate target names
    if(TARGET ${name})
        message(SEND_ERROR "'cmakejs_create_napi_addon()' given target '${name}' which is already exists. Please choose a unique name for this Addon target.")
        return()
    endif()

    set(options)
    set(args ALIAS NAMESPACE NAPI_VERSION)
    set(list_args)
    cmake_parse_arguments(ARG "${options}" "${args}" "${list_args}" "${ARGN}")

    # Generate the identifier for the resource library's namespace
    set(ns_re "[a-zA-Z_][a-zA-Z0-9_]*")

    if(NOT DEFINED ARG_NAMESPACE)
        # Check that the library name is also a valid namespace
        if(NOT name MATCHES "${ns_re}")
            message(SEND_ERROR "Library name is not a valid namespace. Specify the NAMESPACE argument")
            return()
        endif()
        set(ARG_NAMESPACE "${name}")
    else()
        if(NOT ARG_NAMESPACE MATCHES "${ns_re}")
            message(SEND_ERROR "NAMESPACE for ${name} is not a valid C++ namespace identifier (${ARG_NAMESPACE})")
            return()
        endif()
    endif()

    # Needs more validation...
    if(DEFINED ARG_NAPI_VERSION AND (ARG_NAPI_VERSION LESS_EQUAL 0))
        message(SEND_ERROR "NAPI_VERSION for ${name} is not a valid Integer number (${ARG_NAPI_VERSION})")
        return()
    endif()

    if(NOT DEFINED ARG_NAPI_VERSION)
        if(NOT DEFINED NAPI_VERSION)
            # default NAPI version to use if none specified
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

    # Begin a new Napi Addon target

    add_library(${name} SHARED)
    add_library(${name_alt} ALIAS ${name})

    target_link_libraries(${name} cmake-js::addon-base)

    set_property(
      TARGET ${name}
      PROPERTY "${name}_IS_NAPI_ADDON_LIBRARY" TRUE
    )

    set_target_properties(${name}
      PROPERTIES

      LIBRARY_OUTPUT_NAME "${name}"
      PREFIX ""
      SUFFIX ".node"

      ARCHIVE_OUTPUT_DIRECTORY "${CMAKEJS_BINARY_DIR}/lib"
      LIBRARY_OUTPUT_DIRECTORY "${CMAKEJS_BINARY_DIR}/lib"
      RUNTIME_OUTPUT_DIRECTORY "${CMAKEJS_BINARY_DIR}/bin"

      # # Conventional C++-style debug settings might be useful to have...
      # LIBRARY_OUTPUT_NAME_DEBUG "d${name}"
      # ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKEJS_BINARY_DIR}/lib/Debug"
      # LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKEJS_BINARY_DIR}/lib/Debug"
      # RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKEJS_BINARY_DIR}/bin/Debug"
    )

    cmakejs_napi_addon_add_sources(${name} ${ARG_UNPARSED_ARGUMENTS})

    cmakejs_napi_addon_add_definitions(${name}
      PUBLIC
      "CMAKEJS_ADDON_NAME=${name}"
      "NAPI_CPP_CUSTOM_NAMESPACE=${ARG_NAMESPACE}"
      "NAPI_VERSION=${ARG_NAPI_VERSION}"
      "BUILDING_NODE_EXTENSION"
    )

endfunction()

#[=============================================================================[
Add source files to an existing Napi Addon target.

cmakejs_napi_addon_add_sources(<name> [items1...])
cmakejs_napi_addon_add_sources(<name> [BASE_DIRS <dirs>] [items1...])
#]=============================================================================]
function(cmakejs_napi_addon_add_sources name)

    # Check that this is a Node Addon target
    get_target_property(is_addon_lib ${name} ${name}_IS_NAPI_ADDON_LIBRARY)
    if(NOT TARGET ${name} OR NOT is_addon_lib)
        message(SEND_ERROR "'cmakejs_napi_addon_add_sources()' called on '${name}' which is not an existing napi addon library")
        return()
    endif()

    set(options)
    set(args BASE_DIRS)
    set(list_args)
    cmake_parse_arguments(ARG "${options}" "${args}" "${list_args}" "${ARGN}")

    if(NOT ARG_BASE_DIRS)
        # Default base directory of the passed-in source file(s)
        set(ARG_BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    _cmakejs_normalize_path(ARG_BASE_DIRS)
    get_filename_component(ARG_BASE_DIRS "${ARG_BASE_DIRS}" ABSOLUTE)

    # Generate the identifier for the resource library's namespace
    get_target_property(lib_namespace "${name}" ${name}_ADDON_NAMESPACE)

    # All remaining unparsed args 'should' be source files for this target, so...
    foreach(input IN LISTS ARG_UNPARSED_ARGUMENTS)

        _cmakejs_normalize_path(input)
        get_filename_component(abs_in "${input}" ABSOLUTE)
        file(RELATIVE_PATH relpath "${ARG_BASE_DIRS}" "${abs_in}")
        if(relpath MATCHES "^\\.\\.")
            # For now we just error on files that exist outside of the source dir.
            message(SEND_ERROR "Cannot add file '${input}': File must be in a subdirectory of ${ARG_BASE_DIRS}")
            continue()
        endif()

        target_sources(${name} PRIVATE "${abs_in}")

    endforeach()

endfunction()

#[=============================================================================[
Add pre-processor definitions to an existing Napi Addon target.

cmakejs_napi_addon_add_definitions(<name> [items1...])
cmakejs_napi_addon_add_definitions(<name> <INTERFACE|PUBLIC|PRIVATE> [items1...] [<INTERFACE|PUBLIC|PRIVATE> [items2...] ...])
#]=============================================================================]
function(cmakejs_napi_addon_add_definitions name)

    # Check that this is a Node Addon target
    get_target_property(is_addon_lib ${name} ${name}_IS_NAPI_ADDON_LIBRARY)
    if(NOT TARGET ${name} OR NOT is_addon_lib)
        message(SEND_ERROR "'cmakejs_napi_addon_add_definitions()' called on '${name}' which is not an existing napi addon library")
        return()
    endif()

    set(options)
    set(args)
    set(list_args INTERFACE PRIVATE PUBLIC)
    cmake_parse_arguments(ARG "${options}" "${args}" "${list_args}" "${ARGN}")

    if(DEFINED ARG_INTERFACE)
        foreach(item IN LISTS ARG_INTERFACE)
            target_compile_definitions(${name} INTERFACE "${item}")
        endforeach()
    endif()

    if(DEFINED ARG_PRIVATE)
        foreach(item IN LISTS ARG_PRIVATE)
            target_compile_definitions(${name} PRIVATE "${item}")
        endforeach()
    endif()

    if(DEFINED ARG_PUBLIC)
        foreach(item IN LISTS ARG_PUBLIC)
            target_compile_definitions(${name} PUBLIC "${item}")
        endforeach()
    endif()

    foreach(input IN LISTS ARG_UNPARSED_ARGUMENTS)
        target_compile_definitions(${name} "${item}")
    endforeach()

endfunction()
