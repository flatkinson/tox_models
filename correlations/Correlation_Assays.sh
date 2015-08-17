#! /bin/bash

logmsg() {
    echo "[`date +"%H:%M:%S"`] $1" 1>&2
}

# cat symbols.txt | while read symbol

for symbol in MTOR DRD4
do
    logmsg "Starting $symbol..."

    symbol=${symbol} ipython nbconvert --execute --to=html --output=Correlation_Assays_${symbol}.html Correlation_Assays.ipynb 1>/dev/null 2>&1

    sleep 5

    if grep -qF 'AssertionError' Correlation_Assays_${symbol}.html
    then
    
        logmsg "$symbol failed."

        rm Correlation_Assays_${symbol}.html
        
    else
    
        logmsg "$symbol succeeded."
    fi
done
