
# Include Node-API headers
execute_process(
  COMMAND node -p "require('node-api-headers').include_dir"
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE NODE_API_HEADERS_DIR
)
string(REGEX REPLACE "[\r\n\"]" "" NODE_API_HEADERS_DIR ${NODE_API_HEADERS_DIR})
set(NODE_API_HEADERS_DIR "${NODE_API_HEADERS_DIR}"
  CACHE
  PATH
  "Node API Headers directory."
  FORCE
)

# Include Node-API wrappers
execute_process(
  COMMAND node -p "require('node-addon-api').include"
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE NODE_ADDON_API_DIR
)
string(REGEX REPLACE "[\r\n\"]" "" NODE_ADDON_API_DIR ${NODE_ADDON_API_DIR})
set(NODE_ADDON_API_DIR "${NODE_ADDON_API_DIR}"
  CACHE
  PATH
  "Node Addon API Headers directory."
  FORCE
)

# Create a Node C++ Addon as a dynamic library
add_library (napi-addon-base INTERFACE)
add_library (napi-addon::base ALIAS napi-addon-base)
target_include_directories (napi-addon-base INTERFACE ${CMAKE_JS_INC} ${NODE_API_HEADERS_DIR} ${NODE_ADDON_API_DIR})
target_sources (napi-addon-base INTERFACE ${CMAKE_JS_SRC})
target_link_libraries (napi-addon-base ${CMAKE_JS_LIB})
set_target_properties (napi-addon-base
  PROPERTIES
  ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)
if (MSVC AND CMAKE_JS_NODELIB_DEF AND CMAKE_JS_NODELIB_TARGET)
  execute_process (COMMAND ${CMAKE_AR} /def:${CMAKE_JS_NODELIB_DEF} /out:${CMAKE_JS_NODELIB_TARGET} ${CMAKE_STATIC_LINKER_FLAGS})
endif ()

function(_napi_addon_normalize_path var)
  set(path "${${var}}")
  file(TO_CMAKE_PATH "${path}" path)
  while(path MATCHES "//")
      string(REPLACE "//" "/" path "${path}")
  endwhile()
  string(REGEX REPLACE "/+$" "" path "${path}")
  set("${var}" "${path}" PARENT_SCOPE)
endfunction()

function(add_napi_addon name)

  set(args ALIAS NAMESPACE)
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

  # set(libname "${name}")

  add_library(${name} SHARED)
  if(ARG_ALIAS)
    add_library("${ARG_ALIAS}" ALIAS ${name})
  elseif(ARG_NAMESPACE)
    add_library(${ARG_NAMESPACE}::${name} ALIAS ${name})
  else()
    add_library(napi-addon::${name} ALIAS ${name})
  endif()

  target_compile_definitions(${name} PRIVATE "NAPI_CPP_CUSTOM_NAMESPACE=${ARG_NAMESPACE}")

  target_include_directories(${name}
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include/${PROJECT_NAME}>
    $<INSTALL_INTERFACE:include/${PROJECT_NAME}>
  )

  target_link_libraries(${name} napi-addon::base)

  set_property(TARGET ${name} PROPERTY ${name}_IS_NAPI_ADDON_LIBRARY TRUE)
  set_target_properties (${name}
    PROPERTIES
    LIBRARY_OUTPUT_NAME "${name}"
    PREFIX ""
    SUFFIX ".node"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
  )

  napi_addon_add_sources(${name} ${ARG_UNPARSED_ARGUMENTS})

endfunction()

function(napi_addon_add_sources name)

  get_target_property(is_addon_lib ${name} ${name}_IS_NAPI_ADDON_LIBRARY)
  if(NOT TARGET ${name} OR NOT is_addon_lib)
    message(SEND_ERROR "napi_addon_add_sources called on target '${name}' which is not an existing napi addon library")
    return()
  endif()

  set(options)
  set(args BASE_DIRS)
  set(list_args)
  cmake_parse_arguments(ARG "${options}" "${args}" "${list_args}" "${ARGN}")

  if(NOT ARG_BASE_DIRS)
    set(ARG_BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR})
  endif()
  _napi_addon_normalize_path(ARG_BASE_DIRS)
  get_filename_component(ARG_BASE_DIRS "${ARG_BASE_DIRS}" ABSOLUTE)

  # Generate the identifier for the resource library's namespace
  get_target_property(lib_namespace "${name}" ${name}_ADDON_NAMESPACE)

  foreach(input IN LISTS ARG_UNPARSED_ARGUMENTS)
    _napi_addon_normalize_path(input)
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

function(napi_addon_include_directories name)
  # target_include_directories(${name}
  #   PUBLIC
  #   $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include/${PROJECT_NAME}>
  #   $<INSTALL_INTERFACE:include/${PROJECT_NAME}>
  # )
endfunction()