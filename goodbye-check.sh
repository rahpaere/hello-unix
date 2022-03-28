#! /bin/sh

NAME=goodbye
MESSAGE='Goodbye for now.'
MSGTYPE='valediction'

if ! test -f $NAME.tar.gz
then
	echo Run this program in the same directory as your $NAME.tar.gz archive.
	exit 1
fi

# exit on errors
set -e

# set up temporary working space
TMP=`mktemp -d`
trap 'rm -rf "$TMP"' EXIT
PROJECT="$TMP/$NAME"

echo Unpacking...
tar -xz -f $NAME.tar.gz -C "$TMP"

if test `ls "$TMP" | wc -l` -gt 1
then
	echo There was more than one top-level file in the archive\!
	echo Perhaps you forgot to archive the project in its directory.
fi

if test -d "$PROJECT"
then
	echo Found $NAME project directory.
else
	echo Missing $NAME project directory\!
	exit 1
fi

if test `ls "$PROJECT" | wc -l` -gt 1
then
	echo There are more files in the project directory than expected\!
	echo Perhaps you forgot to delete extraneous files.
fi

if test -f "$PROJECT/$NAME.c"
then
	echo Found $NAME.c.
else
	echo Missing $NAME.c\!
	exit 1
fi

echo Compiling...
gcc -g -Wall -o "$PROJECT/$NAME" "$PROJECT/$NAME.c"

"$PROJECT/$NAME" > "$TMP/output"
echo "$MESSAGE" > "$TMP/expected"
if diff "$TMP/expected" "$TMP/output"
then
	echo The program prints the expected $MSGTYPE.
else
	echo The program does not print the expected $MSGTYPE\!
fi

echo Done.
