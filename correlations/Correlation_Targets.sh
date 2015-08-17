#! /bin/bash

for species in Human Rat
do

    species=${species} runipy Correlation_Targets.ipynb Correlation_Targets_${species}.ipynb #\
        # && ipython nbconvert --to html Correlation_Targets_${species}.ipynb \
        # && rm -f Correlation_Targets_${species}.ipynb

done
