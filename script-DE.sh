#!/bin/bash

FOLDER=script_files_DE

rm -fr $FOLDER
mkdir -p $FOLDER
mkdir -p $FOLDER/classes
cp de-tagged.txt $FOLDER/00_source.txt
# Remove empty lines
sed -e '/^$/d' $FOLDER/00_source.txt > $FOLDER/01_noempty.txt
# Count the number of occurrences and prepend it to each line, then sort by it
cat $FOLDER/01_noempty.txt | sort | uniq -c | sort -k1,1nr -k2,2 > $FOLDER/02_unique.txt
# Remove leading spaces and space after the count from uniq, remove the first tab
sed -e 's/\s*\(.*\)\s\(.*\)\s\(.*\)/\1|\2|\3/' $FOLDER/02_unique.txt > $FOLDER/03_nospace.txt
# Separate word classes (separate by third column)
awk -F'|' '{print $0>"'$FOLDER'/classes/04_"$3".txt"}' $FOLDER/03_nospace.txt

#NOUN:
#Separate schwache
cat de-noun-schwache.txt | while read line
do
	awk -F'|' -v pattern="$line" 'IGNORECASE=1 {if($0 ~ /Gender=Masc/ && $2 ~ pattern) {print $0>>"'$FOLDER'/classes/05_NOUN_schwach.txt"}}' $FOLDER/classes/04_NOUN.txt
done
grep -F -x -v -f $FOLDER/classes/05_NOUN_schwach.txt $FOLDER/classes/04_NOUN.txt > $FOLDER/classes/05_NOUN.txt
#Convert everything to nominativ
julia 05_NOUN.jl $FOLDER/classes/05_NOUN.txt $FOLDER/classes/06_NOUN.txt
#Recognize classes
julia 06_NOUN.jl $FOLDER/classes/06_NOUN.txt $FOLDER/classes/07_NOUN.txt

echo "Word count: " $(cat $FOLDER/03_nospace.txt | wc -l)

