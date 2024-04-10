#!/bin/bash

SAMPLE_DIR="/home/liangyu/1_Project/7_Nano/EpiNano/test_data/make_predictions"
MISC_DIR="/home/liangyu/1_Project/7_Nano/EpiNano/misc"
WORK_DIR="/home/liangyu/1_Project/7_Nano/1_Results/1_TestData" 
CMD_DIR="/home/liangyu/1_Project/7_Nano/EpiNano" 
JAR_DIR="/home/liangyu/3_software/jvarkit/dist"
MODEL_DIR="/home/liangyu/1_Project/7_Nano/EpiNano/models"


#Create dict file for refernece genome
java -jar /home/liangyu/bin/picard.jar CreateSequenceDictionary -R $SAMPLE_DIR/ref.fa -O $SAMPLE_DIR/ref.fa.dict

###************************************************************For Epinano-Error module (PAIRED data required)************************************************************
#STEP 1. compute varitants/error frequencies from bam file
python3.6 $CMD_DIR/Epinano_Variants.py -n 6 -R $SAMPLE_DIR/ref.fa -b $SAMPLE_DIR/wt.bam -s $MISC_DIR/sam2tsv.jar --type t
python3.6 $CMD_DIR/Epinano_Variants.py -n 6 -R $SAMPLE_DIR/ref.fa -b $SAMPLE_DIR/ko.bam -s $MISC_DIR/sam2tsv.jar --type t

STEP 2. Predict RNA modifications (for EpiNano_error)
Rscript $CMD_DIR/Epinano_DiffErr.R -k $SAMPLE_DIR/ko.plus_strand.per.site.csv  -w $SAMPLE_DIR/wt.plus_strand.per.site.csv -t 5 -o wt_ko -c 30 -f mis  -d 0.1 -p


###************************************************************For Epinano-SVM module (PAIRED data recommended)************************************************************
#STEP 1. Generate the base-called features organized in 5-mer windows
python $MISC_DIR/Slide_Variants.py $SAMPLE_DIR/wt.plus_strand.per.site.csv 5
python $MISC_DIR/Slide_Variants.py $SAMPLE_DIR/ko.plus_strand.per.site.csv 5

#STEP 2. Extract current intensity values
bash $CMD_DIR/Epinano_Current.sh -b $SAMPLE_DIR/wt.bam -f $SAMPLE_DIR/ref.fa -t 6 -m g 
bash $CMD_DIR/Epinano_Current.sh -b $SAMPLE_DIR/ko.bam -f $SAMPLE_DIR/ref.fa -t 6 -m g 


#STEP 3. Extract current intensity values
python $CMD_DIR/misc/Epinano_sumErr.py --file ko.plus_strand.per.site.var.csv --out ko.sum_err.csv --kmer 0
python $CMD_DIR/misc/Epinano_sumErr.py --file wt.plus_strand.per.site.var.csv --out wt.sum_err.csv --kmer 0

#STEP 4. predict using pretrained SVM models 
### (pip3 install -U scikit-learn==0.20.2) ### Update the scikiet pack if needed

python3.6 $CMD_DIR/Epinano_Predict.py -o wt.SVM_Predict -M $MODEL_DIR/rrach.q3.mis3.del3.linear.dump -p $SAMPLE_DIR/wt.plus_strand.per_site.5mer.csv -cl 8,13,23
python3.6 $CMD_DIR/Epinano_Predict.py -o ko.SVM_Predict -M $MODEL_DIR/rrach.q3.mis3.del3.linear.dump -p $SAMPLE_DIR/ko.plus_strand.per.site.5mer.csv -cl 8,13,23

#STEP 5. generate delta-features" (results will be EXPORTED UNDER THE WORKDIR)
python3.6 $CMD_DIR/misc/Epinano_make_delta.py $SAMPLE_DIR/ko.plus_strand.per.site.5mer.csv $SAMPLE_DIR/wt.plus_strand.per.site.5mer.csv 5 5 > $SAMPLE_DIR/wt_ko_delta.5mer.csv

#STEP 6. predict using pretrained SVM models with delta features" (Results will be saved as:wt_ko_2021.DeltaMis3.DeltaDel3.DeltaQ3.MODEL.rrach.deltaQ3.deltaMis3.deltaDel3.linear.dump.csv )
python3.6 $CMD_DIR/Epinano_Predict.py -o wt_ko_2021 -M $MODEL_DIR/rrach.deltaQ3.deltaMis3.deltaDel3.linear.dump -p $SAMPLE_DIR/wt_ko_delta.5mer.csv -cl 7,12,22

#STEP 7. plot SVM-based prediction p-values
Rscript $CMD_DIR/Epinano_Plot.R $WORK_DIR/wt_ko_2021.DeltaMis3.DeltaDel3.DeltaQ3.MODEL.rrach.deltaQ3.deltaMis3.deltaDel3.linear.dump.csv
