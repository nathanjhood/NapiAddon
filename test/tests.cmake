# Make a list of tests to do (should match the test's filename)
list(APPEND TESTS
  hello
  version
  hello_v7
  version_v7
  index
)

# define a function to simplify adding tests
function(do_test arg)
    add_test(
      NAME test_${arg}
      COMMAND "${NODE_EXECUTABLE}" "./test/${arg}.js"
      WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
    )
    set_tests_properties(test_${arg}
      PROPERTIES PASS_REGULAR_EXPRESSION " passed."
    )
endfunction(do_test)

# run the tests
foreach(TEST IN LISTS TESTS)
    do_test("${TEST}")
endforeach()
