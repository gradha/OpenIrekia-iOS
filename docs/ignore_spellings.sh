#!/bin/sh
# vim:tabstop=4 shiftwidth=4 encoding=utf-8

for f in `find . -name "*.txt"`
do
	echo "Adding words to ignore lists. $f"
	IG_FILE="$f.aspell_ignore"
	cat "$f" | aspell list --lang=en --encoding=utf-8 | \
		sort | uniq > tmp.txt && \
		cat "$IG_FILE" >> tmp.txt && \
		sort tmp.txt | uniq > "$IG_FILE" && \
		rm tmp.txt 
done

git status
