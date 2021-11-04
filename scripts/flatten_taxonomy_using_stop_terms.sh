#!/bin/bash

display_usage() {
  echo -e "Flattens a given taxonomy using the stop terms list provided. This means that the new taxonomy will contain only two elements: the first element and the element that is present in the stop terms list.\n"
  echo -e "This script output is written to \"<taxonomy>.flattened_stop_terms\"."
  echo -e "\nUsage:"
  echo -e "\t `basename $0` <taxonomy> <stop_terms_list>"
}

if [[ $1 == "--help" ]]; then
  display_usage
  exit 1
fi

if [[ ! $# -eq 2 ]]
then
  tput setaf 1
  echo -e "This script requires two arguments.\n"
  tput sgr0
  display_usage
  exit 1
fi

TEMP_WORKING_DIR=$(mktemp -d /tmp/get_taxonomy_from_stop_terms.XXXXXXX)

TAXONOMY_FILE=$1
STOP_TERMS_FILE=$2

grep -w -f "${STOP_TERMS_FILE}" "${TAXONOMY_FILE}" | cut -f1 -d';' > ${TEMP_WORKING_DIR}/tmp1.taxonomy_first_column
grep -wo -f "${STOP_TERMS_FILE}" "${TAXONOMY_FILE}" > ${TEMP_WORKING_DIR}/tmp2.taxonomy_stop
 
paste -d ';' ${TEMP_WORKING_DIR}/tmp1.taxonomy_first_column ${TEMP_WORKING_DIR}/tmp2.taxonomy_stop > "${TAXONOMY_FILE}.flattened_stop_terms"
