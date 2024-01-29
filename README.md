# NapiAddon

[A proposed CMake API for cmake-js v8](https://github.com/cmake-js/cmake-js/issues/310) (including a demo consumer project).

![CTest](https://github.com/nathanjhood/NapiAddon/actions/workflows/test.yaml/badge.svg)

The file of interest here is the one named [```CMakeJS.cmake```](https://github.com/nathanjhood/NapiAddon/blob/main/CMakeJS.cmake) - this file is a CMake module that builders can append to their project's ```CMAKE_MODULE_PATH```, and then easily create a new NodeJS C++ Addon as a CMake target by using ```cmakejs_create_napi_addon()```, which creates a target with all the reasonable defaults taken care of for building a Napi Addon - but, intermediate/advanced users still have scope to override any of these defaults by using the usual ```target_compile_definitions()``` and such forth on their Addon target(s), if they so wish.

The proposed API also does not clash with any pre-existing projects, by not imposing itself on users unless they specifically call the function within their build script. Adoption of this proposed API would be entirely optional, and especially helpful for newcomers.

```CMakeJS.cmake``` is fully compatible with the latest cmake-js release without any changes to source.

## Minimal setup

Builders are able to get Addons to compile and run using a very minimal CMake build script:

```.cmake
# CMakeLists.txt

cmake_minimum_required(VERSION 3.15)

# path to CMakeJS.cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

include(CMakeJS)

project (demo)

cmakejs_create_napi_addon(
  # NAME
  addon
  # SOURCES
  src/demo/addon.cpp
)

```

... and that's all you need!

## Extended functionality

The module strives to be unopinionated by providing reasonable fallback behaviours that align closely with typical, expected CMake building conventions.

Optionally, more Addon targets can be created from this API under one single project tree, and helpful variables may also be configured:

```.cmake
cmakejs_create_napi_addon (
  # The name given to the addon target defines 'CMAKEJS_ADDON_NAME'
  addon_v7
  # defines 'NAPI_VERSION' directly. If not set, defaults to 8.
  NAPI_VERSION 7
  # defines 'NAPI_CPP_CUSTOM_NAMESPACE'. If not set, the addon target name is used instead.
  NAMESPACE v7
  # defines 'CMAKEJS_ADDON_ALIAS' for an alias target name. If not set, 'NAPI_CPP_CUSTOM_NAMESPACE' is used instead.
  ALIAS addon::v7
)

cmakejs_napi_addon_add_sources (addon_v7
  # Specify an exact directory for this addon's SOURCES
  BASE_DIRS "${PROJECT_SOURCE_DIR}/src"
  src/demo/addon.cpp
)

cmakejs_napi_addon_add_definitions (addon_v7
  # 'PRIVATE', 'PUBLIC', and 'INTERFACE' definitions are all supported.
  PRIVATE
  # See '<Napi.h>' for the default exceptions policy handling. Can be specified here.
  NAPI_CPP_EXCEPTIONS_MAYBE
)
```

## Backwards compatible

Projects built with cmake-js that don't consume this proposed API would not be affected at all by this module's existence. So, the previous 'manual' way of creating addons with cmake-js will still work, and can even be mixed with targets that use the new API, under the same project tree. Even if the functions are not adopted, builders can still get a little extra help by linking with the ```cmake-js::cmake-js``` interface library:

```.cmake
# including the module will automatically make 'cmake-js::cmake-js' available...
include(CMakeJS)

add_library(addon_v6 SHARED src/demo/addon.cpp)
set_target_properties(addon_v6 PROPERTIES PREFIX "" SUFFIX ".node")
target_link_libraries(addon_v6 PRIVATE cmake-js::cmake-js) # link to resolve all dependencies!
```

The above target should build, while leaving the rest of the target's manual implementation up to the builder.

## Builds with either cmake-js or CMake

All that it takes to compile and run the above minimal build script is to call cmake-js from ```package.json```:

```.sh
$ npm run install
```

or

```.sh
$ yarn install
```

*However*, the ```CMakeJS.cmake``` script does *not depend on being executed by cmake-js*, and can build addons independently of npm/yarn, using just native CMake commands (see ```package.json``` for some more):

```.sh
$ cmake --fresh -S . -B ./build

# ...

$ cmake --build ./build
```

Because of the above, IDE tooling integration should also be assured.

## CTest and CPack

CTest and CPack have also been carefully tested against the demo project, to confirm the proposed API's ability to support both.

```.sh
$ ctest -B ./build

# addon tests output...
```

```.sh
$ cpack -B ./build --config CPackConfig.cmake

# doing zip/tar of addon build....

$ cpack -B ./build --config CPackSourceConfig.cmake

# doing zip/tar of addon source code....
```

See [```package.json```](https://github.com/nathanjhood/NapiAddon/blob/main/package.json) for more native CMake/CTest/CPack commands, and how to automate them.

## Deeper CMake integration

By exporting an interface library under cmake-js' own namespace - ```cmake-js::cmake-js```, the CMakeJS.cmake file can easily be shipped in the cmake-js package tree, making the NodeJS Addon API automatically available to builders by simply having the cmake-js CLI pass in ```-DCMAKE_MODULE_PATH:PATH=/path/to/CMakeJS.cmake```, as well as providing the usual/expected means of integration with vcpkg, and other conventional CMake module consumers.

Builders will also find that their cmake-js - powered Addon targets also work well with CMake's ```export()``` and ```install()``` routines, meaning that their Addon projects also work as CMake modules.

```CMakeJS.cmake``` exports the following CMake targets for linkage options:

```
cmake-js::node-dev        // The NodeJS system installation developer files
cmake-js::node-api        // The C Addon API
cmake-js::node-addon-api  // The C++ Addon API
cmake-js::cmake-js        // The full set of configured Addon API dependencies
```

## Intentions

```CMakeJS.cmake``` as presented is rough/unrefined and missing several features it would be worth looking closer at (although quickly improving), but already presents a working UX proposal.

```CMakeJS.cmake``` has been built against the latest releases of cmake-js and CMake, and tested against several LTS versions of NodeJS. No changes have been made to any of the existing source code for any other project; the API proposal is entirely contained within ```CMakeJS.cmake``` as a drop-in solution for building addons.

## About the demo project

Aside from ```CMakeJS.cmake```, all other files here are presented solely as a 'hello world' demo of a 'typical' Node Addon project which uses the proposed ```CMakeJS.cmake``` API, from the perspective of an end-user. The ```CMakeLists.txt``` file which powers the demo build is kept intentionally minimal - 4 lines of CMake code is all that is required to build an Addon - to show the low barrier of entry, while additional (and entirely optional) extended functionality is also demonstrated as a further proof of concept.

As a bonus: it is possible to add this demo project to another NodeJS project, and watch it build itself automatically, showing the process is working fully. To do so, make a new NodeJS project, and add this repo's URL to the dependencies:

```.json
"dependencies": {
  "@nathanjhood/napi-addon": "https://github.com/nathanjhood/NapiAddon.git"
}
```

Then, try running the initial ```npm/yarn run install``` command as usual. The demo addon will be under ```node_modules/@nathanjhood/napi-addon/build/lib/addon.node``` ready for consuming.

The demo addon is then acquirable in your demo NodeJS project as you would expect:

```.js
const nathan_napi_addon = require("@nathanjhood/napi-addon")

console.log(`Napi Status:  ${nathan_napi_addon.hello()}`);
console.log(`Napi Version: ${nathan_napi_addon.version()}`);
```

### Some recent Napi Addons of mine

- [nathanjhood/NodeRC](https://github.com/nathanjhood/noderc) - CMakeRC as a Napi Addon
- [nathanjhood/base64](https://github.com/nathanjhood/base64) - An open-source base64 encode/decode tool as a Napi Addon
- [hostconfig/modules](https://github.com/hostconfig/modules) - HTML content written and compiled in C++ served via Express as a Napi Addon

### Here is one using ```CMakeJS.cmake```'s targets and functions, alongside native CMake targets, in a single project.

- [nathanjhood/njwt](https://github.com/nathanjhood/njwt) - JWT tool - under construction

Thanks for reading!

[Nathan J. Hood](https://github.com/nathanjhood)
