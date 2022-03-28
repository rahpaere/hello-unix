#! /bin/sh

if ! test -f announce.tar.gz
then
	echo Run this program in the same directory as your announce.tar.gz archive.
	exit 1
fi

# exit on errors
set -e

# set up temporary working space
TMP=`mktemp -d`
trap 'rm -rf "$TMP"' EXIT
PROJECT="$TMP/announce"

echo Unpacking...
tar -xz -f announce.tar.gz -C "$TMP"

if test `ls "$TMP" | wc -l` -gt 1
then
	echo There was more than one top-level file in the archive\!
	echo Perhaps you forgot to archive the project in its directory.
fi

if test -d "$PROJECT"
then
	echo Found announce project directory.
else
	echo Missing announce project directory\!
fi

if test `ls "$PROJECT" | wc -l` -gt 4
then
	echo Too many files in project directory\!
	echo Perhaps you forgot to delete extraneous files.
fi

for file in main.c announce.c announce.h Makefile
do
	if test -f "$PROJECT/$file"
	then
		echo "Found $file."
	else
		echo "Missing $file!"
		exit 1
	fi
done

echo Making...
make -s -C "$PROJECT"

echo Announcing...
"$PROJECT/announce"

echo Cleaning up...
make -s -C "$PROJECT" clean
if test `ls "$PROJECT" | wc -l` -ne 4
then
	echo Project directory is not clean\!
fi

echo Checking C conventions...

gcc -c -o "$TMP/announce.o" "$PROJECT/announce.c"
if nm "$TMP/announce.o" | grep -q '\s\+T\s\+announce$'
then
	echo The announce function is correctly defined in announce.c.
else
	echo The announce function is not defined in announce.c\!
fi

gcc -c -o "$TMP/main.o" "$PROJECT/main.c"
if nm "$TMP/main.o" | grep -q '\s\+U\s\+announce$'
then
	echo The announce function is correctly linked into main.c.
else
	echo The announce function is not linked into main.c\!
fi

gcc -H -E "$PROJECT/announce.c" 2>"$TMP/announce.i" >/dev/null
if grep -q "^\.\+\s\+.*/announce\.h$" "$TMP/announce.i"
then
	echo The announce.c source file correctly includes the announce.h header.
else
	echo The announce.c source file does not include the announce.h header\!
fi
if grep -q '^\.\+\s\+.*\.c$' "$TMP/announce.i"
then
	echo The announce.c source file uses \#include on a .c file\!
else
	echo The announce.c source file correctly links to other source files.
fi

gcc -H -E "$PROJECT/main.c" 2>"$TMP/main.i" >/dev/null
if grep -q '^\.\+\s\+.*/announce\.h$' "$TMP/main.i"
then
	echo The main.c source file correctly includes the announce.h header.
else
	echo The main.c source file does not include the announce.h header\!
fi
if grep -q '^\.\+\s\+.*\.c$' "$TMP/main.i"
then
	echo The main.c source file uses \#include on a .c file\!
else
	echo The main.c source file correctly links to other source files.
fi

gcc -P -E "$PROJECT/announce.h" > "$TMP/once"
gcc -P -E -include "$PROJECT/announce.h" "$PROJECT/announce.h" > "$TMP/twice"
if diff -q "$TMP/once" "$TMP/twice"
then
	echo The announce.h header is correctly idempotent.
else
	echo The announce.h header is not idempotent\!
	echo Perhaps you did not use a double-inclusion guard.
fi

echo Done.
