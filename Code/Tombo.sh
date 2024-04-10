#!/bin/bash

tombo_dir="/home/liangyu/anaconda3/envs/tombo/bin"
fast5dir="/mnt/Knives/1_data/1_Nanopour"
genome_dir="/mnt/Wolfwood/2020_Nanopore"
work_dir="/home/liangyu/1_Project/7_Nano/Tombo"

for i in $(cat $fast5dir/sample.list);
do


	#STEP 1. Re-squiggleing fast5 reads
	$tombo_dir/tombo resquiggle ${fast5dir}/$i $genome_dir/Atha_genome.fasta --processes 4 --num-most-common-errors 5 --overwrite

	#STEP 2. detect modificaitons
	$tombo_dir/tombo detect_modifications alternative_model --alternate-bases 6mA --dna --fast5-basedirs ${fast5dir}/$i --statistics-file-basename $i --processes 10 

	#STEP 3. plot raw signal at most significant m6A locations
	tombo plot most_significant --fast5-basedirs ${fast5dir}/$i \
    		--statistics-filename ${work_dir}/$i.tombo.stats \
    		--plot-alternate-model 6mA \
    		--pdf-filename ${work_dir}/$i.m6A_most_significant.pdf


	#STEP 4. produces "estimated fraction of modified reads" genome browser files
	$tombo_dir/tombo text_output browser_files --statistics-filename $work_dir/$i.tombo.stats \
   		--file-types dampened_fraction statistic --browser-file-basename $i

	#STEP 5. produce successfully processed reads coverage file for reference
	$tombo_dir/tombo text_output browser_files --fast5-basedirs ${fast5dir}/$i \
    		--file-types coverage --browser-file-basename $i

	#STEP 6. generate the fasta sequences of certain genomic regions
	$tombo_dir/tombo text_output signif_sequence_context --statistics-filename $work_dir/$i.tombo.stats \
             --genome-fasta $genome_dir/Atha_genome.fasta --num-regions 1000 --num-bases 50
done

