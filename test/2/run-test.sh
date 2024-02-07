#!/bin/bash

DATA_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

docker run --rm -it \
   -v ${DATA_DIR}/ptc-cache:/ptc-cache \
   -v ${DATA_DIR}:/data \
      pegi3s/phylogenetic-tree-collapser collapse-tree.py \
         --input /data/diptera_tree.con \
         --input-format nexus \
         --taxonomy-stop-terms /data/stop_terms \
         --output /data/collapsed_phylogram_diptera_tree.con.nwk \
         --output-type phylogram \
         --output-collapsed-nodes /data/collapsed_phylogram_diptera_tree.con.tsv

declare -a result_files
result_files=("diptera_tree.con.nwk.taxonomy" "diptera_tree.con.nwk.sequence_to_species_mapping" "diptera_tree.con.nwk" "collapsed_phylogram_diptera_tree.con.nwk" "collapsed_phylogram_diptera_tree.con.tsv")

echo -n "Checking results ... "

for element in "${result_files[@]}"; do
    diff "${DATA_DIR}/${element}" "${DATA_DIR}/results/${element}"
    if [ $? -ne 0 ]; then
      echo "FAILED"
      echo -e "\tTest error: ${DATA_DIR}/${element} is different to ${DATA_DIR}/results/${element}"
      exit 1
    fi
done

echo "OK"

echo -n "Cleaning output files ... "
cd ${DATA_DIR} && rm -f "${result_files[@]}"
echo "DONE"