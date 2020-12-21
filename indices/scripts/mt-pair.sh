#!/bin/bash
#list all data that can be used to evaluate MT from language in ARG1 to language in ARG2 (files where the source and target texts exists, disregarding translationese effect)

function die() { echo "$@" >&2; exit 1; }

src="$1"
tgt="$2"

[ ! -z "$tgt" ] || die "usage: $0 en cs   ... generates auto-mt-en2cs"

tempfile=$(tempfile)
outfile=${0%/*}/../auto-mt-$src"2"$tgt

echo "# $0 is generating $outfile" >&2

documents="${0%/*}/../../documents"
[ -d "$documents" ] || die "Failed to locate the root of documents directory"

# OSt and the corresponding TT, in both directions
# we first generate a secondary tempfile
find $documents -type f -not -name "README.md" \
| grep ".$src.TT$tgt" \
| grep -v 'align$' \
>> $tempfile.2
find $documents -type f -not -name "README.md" \
| grep ".$tgt.TT$src" \
| grep -v 'align$' \
>> $tempfile.2
# and then put this secondary tempfile to the main one
cat $tempfile.2 >> $tempfile
# remember to add the source files, i.e. OSt
cat $tempfile.2 \
| sed "s/\.TT\($src\|$tgt\)[1-4]*/.OSt/" \
>> $tempfile

## TAUS files
find -L $documents/taus -type f \
| grep "$src"-"$tgt""\|""$tgt"-"$src" \
>> $tempfile

## Intercorp files
find -L $documents/confidential/intercorp -type f -name "aligned*" \
| grep "$src"2"$tgt""\|""$tgt"2"$src" \
| grep "aligned.$src\|aligned.$tgt" \
>> $tempfile

## WMT19 ELITR Test Suite files (only en, de, cs; sometimes tri-parallel)
find -L $documents/wmt19-elitr-testsuite/reference -type f -name "*.$src" -o -name "*.$tgt" \
>> $tempfile

cat > $outfile << EOFMARK
# Generated by elitr-testset/indices/scripts/$0"
# Automatically generated index for MT evaluation from $src into $tgt.
# This set of files disregards the effect of translationese (i.e. $tgt could
# have been the original language of the document)
# Multiple references can appear.
#
#
# TEMPORARY BUG: Accidentally, documents with only 1 file (i.e. missing one of
# the sides) might be also included).
#
# IMPROVEMENT NEEDED: Group files of a given document
# IMPROVEMENT NEEDED: Help SLTev know what is the source and what is the target
#
# BUG: If a language pair has multiple references but we get it in the reverse direction, we get *multiple sources*
# elitr-testset/documents/iwslt2020-nonnative-slt/devset/antrecorp-01_teddy.en.OSt
# elitr-testset/documents/iwslt2020-nonnative-slt/devset/antrecorp-01_teddy.en.OSt
# elitr-testset/documents/iwslt2020-nonnative-slt/devset/antrecorp-01_teddy.en.TTcs1
# elitr-testset/documents/iwslt2020-nonnative-slt/devset/antrecorp-01_teddy.en.TTcs2

EOFMARK

cat $tempfile \
| sort \
| sed "s|$documents|elitr-testset/documents|" \
>> $outfile

rm $tempfile
