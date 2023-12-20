
@load "cpot"

@include "awkpot"
# https://github.com/crap0101/awkpot
@include "testing"
# https://github.com/crap0101/awk_testing


BEGIN {
    testing::start_test_report()


    # TEST rindex
    awkpot::random(0, 0, 1)
    split("abcde foobar barbazbar", a, " ")
    for (i in a) {
	start = awkpot::random(length(a[i])+1)
	end = awkpot::random(length(a[i])+1)
	start = start ? start : 1
	end = end ? end : 1
	s = substr(a[i], start, end)
	testing::assert_true(cpot::rindex(a[i], s), 1, sprintf("rindex <%s> <%s>", a[i], s))
	for (j=1; j<=length(a[i]); j++) {
	    s = substr(a[i], 1, j)
	    testing::assert_true(cpot::rindex(a[i], s), 1, sprintf("rindex <%s> <%s>", a[i], s))
	    s = substr(a[i], j)
	    testing::assert_true(cpot::rindex(a[i], s), 1, sprintf("rindex <%s> <%s>", a[i], s))
	}
    }
    testing::assert_true(cpot::rindex("barr", "r"), 1, "rindex barr r")
    testing::assert_true(cpot::rindex("barr", "rr"), 1, "rindex barr rr")
    testing::assert_true(cpot::rindex("barr", "ar"), 1, "rindex barr ar")
    testing::assert_true(cpot::rindex("barr", "b"), 1, "rindex barr b")
    testing::assert_true(cpot::rindex("barr", "ba"), 1, "rindex barr ba")
    testing::assert_true(cpot::rindex("bbarr", "ba"), 1, "rindex bbarr ba")
    testing::assert_true(cpot::rindex("bbarr", "bb"), 1, "rindex bbarr bb")
    # test no match
    testing::assert_false(cpot::rindex("bbarr", "x"), 1, "! rindex bbarr x")
    testing::assert_false(cpot::rindex("bbarr", ""), 1, "! rindex bbarr \"\"")
    testing::assert_false(cpot::rindex("", "bb"), 1, "! rindex \"\" bb")
    testing::assert_false(cpot::rindex("bb", "bba"), 1, "! rindex bb bba")
    # test fatal
    cmd = sprintf("%s -l cpot 'BEGIN {cpot::rindex()}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "! rindex: wrong call, no args: fatal")
    cmd = sprintf("%s -l cpot 'BEGIN {cpot::rindex(1)}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "! rindex: wrong call, not enough args: fatal")
    cmd = sprintf("%s -l cpot 'BEGIN {cpot::rindex(1, 2, 3)}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "! rindex: wrong call, too many args: fatal")
    cmd = sprintf("%s -l cpot 'BEGIN {a[0];cpot::rindex(2, a)}'", ARGV[0])
    testing::assert_false(awkpot::exec_command(cmd), 1, "! rindex: wrong call, wrong type arg: fatal")

    # TEST setsym
    delete a
    PROCINFO["sorted_in"] = "@ind_num_asc"

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
