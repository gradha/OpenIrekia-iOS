#!/bin/sh
# vim:tabstop=4 shiftwidth=4 encoding=utf-8

EXTRA=./.extra.aspell
for f in `find . -name "*.txt"`
do
	echo "Spellchecking $f"
	IG_FILE="$f.aspell_ignore"
	touch "$IG_FILE" && \
		aspell --lang=en --encoding=utf-8 create master $EXTRA < "$IG_FILE" && \
		aspell check "$f" --lang=en --encoding=utf-8 --add-extra-dicts $EXTRA && \
		rm $EXTRA
done

git status
