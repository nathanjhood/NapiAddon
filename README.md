# NapiAddon

[some ideas for cmake-js v8](https://github.com/cmake-js/cmake-js/issues/310)

The file of interest here is the one named ```NapiAddon.cmake``` - this file is a rough CMake module that builders can include in their project's ```CMAKE_MODULE_PATH```, and then easily create a new NodeJS C++ Addon as a CMake target, with all the reasonable defaults taken care of - but, intermediate/advanced users still have scope to override any defaults by using the usual ```target_compile_definitions()``` and such forth on their Addon target.

It also does not clash with any pre-existing projects, by not imposing itself on users unless they specifically call the function within their build script. Adoption of this proposed API would be entirely optional, and especially helpful for newcomers.

By exporting an interface library under cmake-js' own namespace, the ```NapiAddon.cmake``` file can easily be shipped in the cmake-js package, and automatically included by the cmake-js CLI, as well as providing the usual/expected means of integration with vcpkg, and other conventional CMake module consumers.

Builders are able to get Addons to compile and run using a very minimal CMake build script:

```.cmake
# CMakeLists.txt

cmake_minimum_required(VERSION 3.28)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

project (demo)

include(NapiAddon)

add_napi_addon(addon
  # SOURCES
  src/demo/addon.cpp
)

```

All that it takes to compile and run the above minimal build script is to call cmake-js from ```package.json```:

```
$ npm run install

// or

$ yarn install
```

Aside from ```NapiAddon.cmake```, all other files are presented solely as a demo Node Addon project which uses the proposed CMake API.

Thanks for reading!
