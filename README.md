# NapiAddon

[A proposed CMake API for cmake-js v8](https://github.com/cmake-js/cmake-js/issues/310) (including a demo consumer project).

The file of interest here is the one named [```CMakeJS.cmake```](https://github.com/nathanjhood/NapiAddon/blob/main/CMakeJS.cmake) - this file is a rough CMake module that builders can include in their project's ```CMAKE_MODULE_PATH```, and then easily create a new NodeJS C++ Addon as a CMake target, with all the reasonable defaults taken care of - but, intermediate/advanced users still have scope to override any defaults by using the usual ```target_compile_definitions()``` and such forth on their Addon target(s).

It also does not clash with any pre-existing projects, by not imposing itself on users unless they specifically call the function within their build script. Adoption of this proposed API would be entirely optional, and especially helpful for newcomers.

Builders are able to get Addons to compile and run using a very minimal CMake build script:

```.cmake
# CMakeLists.txt

cmake_minimum_required(VERSION 3.12)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

include(CMakeJS)

project (demo)

cmakejs_create_napi_addon(addon
  # SOURCES
  src/demo/addon.cpp
)

```

Optionally, more Addon targets can be created from this API under one project tree, and helpful variables can be exposed:

```.cmake

cmakejs_create_napi_addon(addon_v7
  NAPI_VERSION 7
  NAMESPACE v7
)

cmakejs_napi_addon_add_sources(addon_v7
  # SOURCES
  src/demo/addon.cpp
)

cmakejs_napi_addon_add_definitions(addon_v7
  PRIVATE
  NAPI_CPP_EXCEPTIONS_MAYBE
)
```

All that it takes to compile and run the above minimal build script is to call cmake-js from ```package.json```:

```.sh
$ npm run install
```

or

```.sh
$ yarn install
```

*However*, the ```CMakeJS.cmake``` script does *not depend on being executed by cmake-js*, and will build independently using just CMake commands.

Because of the above, IDE tooling integration should be assured.

By exporting an interface library under cmake-js' own namespace, the CMakeJS.cmake file can easily be shipped in the cmake-js package tree, and automatically included by the cmake-js CLI, as well as providing the usual/expected means of integration with vcpkg, and other conventional CMake module consumers.

```CMakeJS.cmake``` as presented is rough/unrefined and missing several features it would be worth looking closer at, but already presents a working UX proposal.

Aside from ```CMakeJS.cmake```, all other files here are presented solely as a 'hello world' demo of a 'typical' Node Addon project which uses the proposed ```CMakeJS.cmake``` API, from the perspective of an end-user.

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

console.log(nathan_napi_addon.hello());
console.log(`Napi Version: ${nathan_napi_addon.version()}`);
```

Thanks for reading!
