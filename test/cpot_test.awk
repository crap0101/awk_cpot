@load "cpot"

@include "awkpot"
# https://github.com/crap0101/awkpot
@include "testing"
# https://github.com/crap0101/awk_testing

function foo(symstr, val) {
    cpot::setsym(symstr, val)
}

BEGIN {

    testing::start_test_report()

    # TEST setsym
    split("1", a, ":")
    a[0] = @/^.*?x+9$/
    # a[1] is strnum 1
    a[2] = "foo"
    a[3]
    a[4] = ""
    a[5] = 19
    a[6] = invented
    split("v1 v2 v3 v4 v5 v6", av, " ")
    av[0] = "v0"
    for (i in a) {
        r = cpot::setsym(av[i], a[i])
	testing::assert_true(r, 1, sprintf("> setsym: return true [%s]", SYMTAB[av[i]]))
	testing::assert_equal(typeof(SYMTAB[av[i]]), typeof(a[i]), 1, sprintf("> setsym: typeof() [%s|%s]",  typeof(a[i]), typeof(av[i])))
	testing::assert_equal(SYMTAB[av[i]], a[i], 1, sprintf("> setsym: equals [%s]", SYMTAB[av[i]]))
    }

    # test setsym wrong calls
    cmd = sprintf("%s -l cpot 'BEGIN {cpot::setsym()}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "> ! setsym: wrong call, no args: fatal")
    cmd = sprintf("%s -l cpot 'BEGIN {cpot::setsym(\"foo\")}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "> ! setsym: wrong call, too few args: fatal")
    cmd = sprintf("%s -l cpot 'BEGIN {cpot::setsym(\"1\", 11)}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "> ! setsym: wrong symbol: fatal")
    cmd = sprintf("%s -l cpot 'BEGIN {a[2];cpot::setsym(\"foo\", a)}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "> ! setsym: wrong value (array): fatal")

    # report
    testing::end_test_report()
    testing::report()

}
