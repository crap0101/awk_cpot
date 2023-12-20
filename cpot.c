
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "gawkapi.h"

// define these before include awk_extensions.h
#define _DEBUGLEVEL 0
#define __module__ "cpot"
#define __namespace__ "cpot"
static const gawk_api_t *api;
static awk_ext_id_t ext_id;
static const char *ext_version = "0.1";

// ... and now include other own utilities
#include "awk_extensions.h"
// https://github.com/crap0101/laundry_basket/blob/master/awk_extensions.h

static awk_value_t * do_rindex(int nargs, awk_value_t *result, struct awk_ext_func *finfo);
static awk_value_t * do_setsym(int nargs, awk_value_t *result, struct awk_ext_func *finfo);

/* ----- boilerplate code ----- */
int plugin_is_GPL_compatible;

static awk_ext_func_t func_table[] = {
  { "rindex", do_rindex, 2, 2, awk_false, NULL },
  { "setsym", do_setsym, 2, 2, awk_false, NULL },
};

__attribute__((unused)) static awk_bool_t (*init_func)(void) = NULL;


int dl_load(const gawk_api_t *api_p, void *id) {
  api = api_p;
  ext_id = (awk_ext_id_t) &id;
  int errors = 0;
  long unsigned int i;
  
  if (api->major_version < 3) { //!= GAWK_API_MAJOR_VERSION
      //    || api->minor_version < GAWK_API_MINOR_VERSION) {
    eprint("incompatible api version:  %d.%d != %d.%d (extension/gawk version)\n",
	   GAWK_API_MAJOR_VERSION, GAWK_API_MINOR_VERSION, api->major_version, api->minor_version);
    exit(1);
  }
  
  for (i=0; i < sizeof(func_table) / sizeof(awk_ext_func_t); i++) {
    if (! add_ext_func(__namespace__, & func_table[i])) {
      eprint("can't add extension function <%s>\n", func_table[0].name);
      errors++;
    }
  }
  if (ext_version != NULL) {
    register_ext_version(ext_version);
  }
  return (errors == 0);
}

/* ----- end of boilerplate code ----------------------- */


static awk_value_t*
do_rindex(int nargs,
	  awk_value_t *result,
	  __attribute__((unused)) struct awk_ext_func *finfo)
{
  /*
   * Find the *last* occurrence of the string at $nargs[1] in the
   * string of $nargs[0]. Return the index of $nargs[0] at which
   * the occurrence was found, or 0.
   */
  assert(result != NULL);
  make_number(0.0, result);

  awk_value_t str, sub;
  size_t istr, isub, max_len, found_at;

  if (nargs > 2)
    fatal(ext_id, "rindex expects two arguments\n");
  
  if (! get_argument(0, AWK_STRING, & str)) {
    if (str.val_type != AWK_STRING)
      fatal(ext_id, "wrong type argument: <%s> (expected: <%s>)\n",
	    _val_types[str.val_type], name_to_string(AWK_STRING));
    else
      fatal(ext_id, "can't retrieve 1st arg\n");
  }
  if (! get_argument(1, AWK_STRING, & sub)) {
    if (sub.val_type != AWK_STRING)
      fatal(ext_id, "wrong type argument: <%s> (expected: <%s>)\n",
	    _val_types[sub.val_type], name_to_string(AWK_STRING));
    else
      fatal(ext_id, "can't retrieve 2nd arg\n");
  }

  if (0 == str.str_value.len ||
      0 == sub.str_value.len ||
      str.str_value.len < sub.str_value.len)
    return result;

  max_len = str.str_value.len - sub.str_value.len;

  for (found_at = isub = istr = 0; istr < str.str_value.len; istr++) {
    //printf("[%c] [%c] (%lu|%lu)\n",str.str_value.str[istr],sub.str_value.str[isub], istr,isub);
    if (isub == sub.str_value.len) { // end of sub, found a match
      found_at = istr - sub.str_value.len + 1;
      isub = 0;
    }
    if (str.str_value.str[istr] != sub.str_value.str[isub++]) {
      isub = 0;
      // re-check from the start of subs
      if (str.str_value.str[istr] != sub.str_value.str[isub++])
	isub = 0;
    }
    // towards str's end, impossible match
    if ((istr > max_len) && isub == 0)
      break;
  }

  if (isub == sub.str_value.len)  // re-check for a dangling match
    found_at = istr - sub.str_value.len + 1;

  if (0 < found_at)
    make_number(found_at, result);
  return result;
}


static awk_value_t*
do_setsym(int nargs,
	  awk_value_t *result,
	  __attribute__((unused)) struct awk_ext_func *finfo)
{
  /*
   * Sets the symbol $nargs[0] (as a string) to the scalar value $nargs[1].
   * Mimic SYMTAB["varname"] = value
   */
  
  assert(result != NULL);
  make_number(0.0, result);
  awk_value_t var_name, var_value, new_val;
  
  if (nargs > 2)
    dprint("two many arguments! 2 expected: symbol, value\n");

  if (! get_argument(0, AWK_STRING, & var_name)) {
    if (var_name.val_type != AWK_STRING)
      fatal(ext_id,"wrong type argument: <%s> (expected: <%s>)\n",
	    _val_types[var_name.val_type], name_to_string(AWK_STRING));
    else
      fatal(ext_id, "can't retrieve 1st arg <%s>\n", var_name.str_value.str);
  }
  dprint("1st arg is type <%s>\n", _val_types[var_name.val_type]);

  if (awk_false == get_argument(1, AWK_UNDEFINED, & var_value)) {
      fatal(ext_id, "2nd argument has wrong type: <%s>", _val_types[var_value.val_type]);
  } else {
    if (var_value.val_type == AWK_ARRAY) {
      fatal(ext_id, "can't set <%s> as array (2nd arg type is <%s>)",
	    var_name.str_value.str, _val_types[var_value.val_type]);
    } else {
      dprint("2nd arg has type <%s>\n", _val_types[var_value.val_type]);
      copy_element(var_value, & new_val);
    }
  }

  if (! sym_update(var_name.str_value.str, & new_val))
    fatal(ext_id, "sym_update failed setting <%s>\n", var_name.str_value.str);

  make_number(1, result); 
  return result;
}

/* compile with (me, not necessary you):
gcc -fPIC -shared -DHAVE_CONFIG_H -c -O -g -I/usr/include -iquote ~/local/include/awk -Wall -Wextra cpot.c && gcc -o cpot.so -shared cpot.o && cp cpot.so ~/local/lib/awk/ && rm cpot.o cpot.so
*/
