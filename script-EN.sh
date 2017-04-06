#!/bin/bash

rm -fr script_files_EN
mkdir -p script_files_EN

# 1 word per line:
cat en-untagged.txt | tr ' ' '\n' > script_files_EN/01_1wpl.txt
# Do a frequency analysis:
cat script_files_EN/01_1wpl.txt | perl -e 'while(<>) { chomp; $h{lc($_)}++ } @k = sort {$h{$b} <=> $h{$a}} keys(%h); foreach $w (@k) { print("$w\t$h{$w}\n") }' > script_files_EN/02_freq.txt
# Remove any line containing a *:
sed '/\*/d' script_files_EN/02_freq.txt > script_files_EN/03_nostar.txt
# Remove all punctuation:
cat script_files_EN/03_nostar.txt | grep -vP '[\pP\`\$]' > script_files_EN/04_nopunctuation.txt
# Remove all digits:
cat script_files_EN/04_nopunctuation.txt | grep -vP '\d.*?\t' > script_files_EN/05_nodigits.txt
# Remove all closed class words:
cat script_files_EN/05_nodigits.txt | perl -e 'open(CCL, "en-closed-class-list.txt"); while(<CCL>) { chomp; $ccl{lc($_)}++ } while(<>) { ($w, $n) = split("\t"); next if exists $ccl{$w}; print }' > script_files_EN/06_openclass.txt

echo "Word count: " $(cat script_files_EN/05_nodigits.txt | wc -l)

