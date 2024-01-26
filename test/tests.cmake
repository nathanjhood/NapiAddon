add_test(
  NAME Hello
  COMMAND "${NODE_EXECUTABLE}" "./test/hello.js"
  WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
)
set_tests_properties(Hello PROPERTIES PASS_REGULAR_EXPRESSION " passed.")

add_test(
  NAME Version
  COMMAND "${NODE_EXECUTABLE}" "./test/version.js"
  WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
)
set_tests_properties(Version PROPERTIES PASS_REGULAR_EXPRESSION " passed.")

add_test(
  NAME HelloAndVersionWithV7
  COMMAND "${NODE_EXECUTABLE}" "./test/index.js"
  WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
)
set_tests_properties(HelloAndVersionWithV7 PROPERTIES PASS_REGULAR_EXPRESSION " passed.")
