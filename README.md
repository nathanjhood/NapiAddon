# NapiAddon

[some ideas for cmake-js v8](https://github.com/cmake-js/cmake-js/issues/310)

The file of interest here is the one named ```CMakeJS.cmake``` - this file is a rough CMake module that builders can include in their project's ```CMAKE_MODULE_PATH```, and then easily create a new NodeJS C++ Addon as a CMake target, with all the reasonable defaults taken care of - but, intermediate/advanced users still have scope to override any defaults by using the usual ```target_compile_definitions()``` and such forth on their Addon target(s).

It also does not clash with any pre-existing projects, by not imposing itself on users unless they specifically call the function within their build script. Adoption of this proposed API would be entirely optional, and especially helpful for newcomers.

By exporting an interface library under cmake-js' own namespace, the ```CMakeJS.cmake``` file can easily be shipped in the cmake-js package tree, and automatically included by the cmake-js CLI, as well as providing the usual/expected means of integration with vcpkg, and other conventional CMake module consumers.

Builders are able to get Addons to compile and run using a very minimal CMake build script:

```.cmake
# CMakeLists.txt

cmake_minimum_required(VERSION 3.28)

# /path/to/CMakeJS.cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

project (demo)

include(CMakeJS)

cmakejs_create_napi_addon(addon
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

```CMakeJS.cmake``` as presented is rough/unrefined, but already presents a working UX proposal.

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
const napi_addon = require("@nathanjhood/napi-addon")

console.log(addon.hello());
console.log(`Napi Version: ${addon.version()}`);
```

Thanks for reading!
