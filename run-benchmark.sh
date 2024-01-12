#!/bin/bash -x

# Compile foldseek
if [ ! -f tool/foldseek ]; then
    wget https://mmseqs.com/foldseek/foldseek-linux-avx2.tar.gz; tar xvzf foldseek-linux-avx2.tar.gz; export PATH=$(pwd)/foldseek/bin/:$PATH
    cp $(pwd)/foldseek/bin/foldseek tool
fi

# Fetch PDBs
if [ ! -d data/pdb ]; then
    curl https://wwwuser.gwdg.de/~compbiol/foldseek/scp40pdb.tar.gz | tar -xz -C data
fi

# Get pdblist
if [ ! -f data/pdblist ]; then
    awk '{print $1}' data/scop_lookup.tsv > data/pdblist
fi

# Compile ssw_test
if [ ! -f tool/ssw_test ]; then
    git clone --depth 1 https://github.com/mengyao/Complete-Striped-Smith-Waterman-Library tool/ssw
    (cd tool/ssw/src && make)
    cp tool/ssw/src/ssw_test tool/ssw_test
fi

# Encode PDBs
if [ ! -d data/token ]; then
	mkdir data/token
	while read line ; do
		array+=($line)
	done < ./data/pdblist

	for id in "${array[@]}"; do
		./tool/foldseek  structureto3didescriptor ./data/pdb/$id  ./data/token/$id.3di
		awk '{print ">" $1} {print $3}' < ./data/token/$id.3di > ./data/token/$id.new3di
	done
	cat ./data/token/*.new3di > tmp/target.fasta
fi

# Run benchmark
./tool/ssw_test -o 10 -e 1 -a data/mat3di.mat -p  tmp/target.fasta tmp/target.fasta > tmp/foldseekswraw

## extracting alignment result from raw file
grep -a -n "^target_name:\|^query_name:\|^optimal_alignment_score:" tmp/foldseekswraw | awk '{print $1,$2}' | awk -F ":" '{print $1,$3}' | awk '{print $2}' |  awk '{ORS=NR%3?"\t":"\n";print}' |awk '{print $2,$1,$3}' |  sort -k1,1 -k3,3nr  > tmp/foldseekswaln

## generate ROCX file
./benchroc.awk data/scop_lookup.tsv <(cat tmp/foldseekswaln) > tmp/foldseeksw.rocx

## calculate auc
 awk '{ famsum+=$3; supfamsum+=$4; foldsum+=$5}END{print famsum/NR,supfamsum/NR,foldsum/NR}' tmp/foldseeksw.rocx
