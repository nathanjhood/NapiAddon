// @file src/demo/addon.cpp

// Required header and C++ flag
#if __has_include(<napi.h>) && BUILDING_NODE_EXTENSION

#include <napi.h>

namespace NAPI_CPP_CUSTOM_NAMESPACE
{

Napi::Value Hello(const Napi::CallbackInfo& info) {
  return Napi::String::New(info.Env(), "addon is online!");
}

Napi::Value Version(const Napi::CallbackInfo& info) {
  return Napi::Number::New(info.Env(), NAPI_VERSION);
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {

  // Export a chosen C++ function under a given Javascript key
  exports.Set(
    Napi::String::New(env, "hello"), // Name of function on Javascript side...
    Napi::Function::New(env, Hello)  // Name of function on C++ side...
  );

  exports.Set(
    Napi::String::New(env, "version"),
    Napi::Function::New(env, Version)
  );

  // The above will expose the C++ function 'Hello' as a javascript function
  // named 'hello', etc...
  return exports;
}

// Register a new addon with the intializer function defined above
NODE_API_MODULE(addon, Init) // (name to use, initializer to use)

} // namespace NAPI_CPP_CUSTOM_NAMESPACE

#else
 #warning "Warning: Cannot find '<napi.h>' - try running 'npm -g install cmake-js'..."
#endif // __has_include(<napi.h>) && BUILDING_NODE_EXTENSION