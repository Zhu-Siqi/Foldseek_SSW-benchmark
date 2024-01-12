# sswbenchmarknew

# Downloading
1. download foldseek/ssw (/tool)
2. download scop-pdb (/data/pdb)

# SSW-Benchmark
1. use foldseek to get 3di
  1. Don't use the encoder.pt to get 3di. It will encode the first and last residues as X, which is invalid for ssw.
2. run ssw with -o -e
3. calculate the average roc as: fold: supfam: fam
