@load "cpot"

@include "awkpot"
# https://github.com/crap0101/awkpot
@include "testing"
# https://github.com/crap0101/awk_testing


BEGIN {
    testing::start_test_report()

    PROCINFO["sorted_in"] = "@ind_num_asc"
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
	at = typeof(a[i])
	avt = typeof(SYMTAB[av[i]])
	testing::assert_true(r, 1, sprintf("setsym: retcode %d [%s]", r, SYMTAB[av[i]]))
	print "***" at "|" avt
	if (awkpot::cmp_version(awkpot::get_version(), "5.3.0", "awkpot::lt", 1, 1))
	    # for the untyped/unassigned change of behaviour (see NOTE_1 in arrlib_test.awk)
	    if (at == "untyped")
		testing::assert_true(avt == at || avt == "unassigned", 1, sprintf("setsym: typeof() [%s|%s]", at, avt))
	else
	    testing::assert_equal(avt, av, 1, sprintf("setsym: typeof() [%s|%s]", at, avt))
	testing::assert_equal(SYMTAB[av[i]], a[i], 1, sprintf("setsym: equals [%s]", SYMTAB[av[i]]))
    }

    # test setsym wrong calls
    cmd = sprintf("%s -l cpot 'BEGIN {cpot::setsym()}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "! setsym: wrong call, no args: fatal")
    cmd = sprintf("%s -l cpot 'BEGIN {cpot::setsym(\"foo\")}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "! setsym: wrong call, too few args: fatal")
    cmd = sprintf("%s -l cpot 'BEGIN {cpot::setsym(\"1\", 11)}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "! setsym: wrong symbol: fatal")
    cmd = sprintf("%s -l cpot 'BEGIN {a[2];cpot::setsym(\"foo\", a)}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "! setsym: wrong value (array): fatal")

    # report
    testing::end_test_report()
    testing::report()

}
