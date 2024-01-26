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

do_test(hello)
do_test(version)
do_test(hello_v7)
do_test(version_v7)
do_test(index)
