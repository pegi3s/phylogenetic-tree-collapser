#!/bin/bash

display_usage() {
  echo -e "Gets the taxonomy information for each sequence in a given phylogenetic tree file in Newick format. For this, each sequence should begin with the species names.\n"
  echo -e "This script outputs two files: the taxonomy and a sequence to species mapping file."
  echo -e "\nUsage:"
  echo -e "\t `basename $0` <input_file>"
  echo -e "\t `basename $0` <input_file> <output_dir> <output_name>"
}

if [[ $1 == "--help" ]]; then
  display_usage
  exit 0
fi

if [[ $# -lt 1 || $# -gt 3 || $# -eq 2 ]]
then
  tput setaf 1
  echo -e "This script requires exacly one or three arguments.\n"
  tput sgr0
  display_usage
  exit 1
fi

MAX_RETRIES=3
RETRY_DELAY=5
TEMP_WORKING_DIR=$(mktemp -d /tmp/get_taxonomy.XXXXXXX)

INPUT=$1
INPUT_NAME=$(basename $INPUT)
INPUT_DIR=$(dirname $INPUT)

if [[ $# -eq 3 ]]
then
	OUTPUT_DIR=$2
	OUTPUT_NAME=$3
else
	OUTPUT_DIR=${INPUT_DIR}
	OUTPUT_NAME=${INPUT_NAME}
fi

echo "Get taxonomy:"
echo -e "\tINPUT = ${INPUT}"
echo -e "\tOUTPUT_DIR = ${OUTPUT_DIR}"
echo -e "\tOUTPUT_NAME = ${OUTPUT_NAME}\n"

OUTPUT_TAXONOMY_FILE=${OUTPUT_DIR}/${OUTPUT_NAME}.taxonomy
OUTPUT_MAPPING_FILE=${OUTPUT_DIR}/${OUTPUT_NAME}.sequence_to_species_mapping

sed 's/(/\n/g; s/\,/\n/g' ${INPUT} | \
	sed 's/\:.*//g' | \
	sed '/^[[:space:]]*$/d' | \
	# Gets rid of lines starting
	grep -v '^[0-9]' | grep -v ';$' > ${TEMP_WORKING_DIR}/1

cut -f1,2 -d'_' ${TEMP_WORKING_DIR}/1 > ${TEMP_WORKING_DIR}/2
paste ${TEMP_WORKING_DIR}/1 ${TEMP_WORKING_DIR}/2 > ${TEMP_WORKING_DIR}/sequence_to_species_mapping

# Sort unique the species file to avoid quering NCBI for the same species multiple times
sort -u ${TEMP_WORKING_DIR}/2 | sed 's/_/+/g' > ${TEMP_WORKING_DIR}/list_of_species

rm -f ${TEMP_WORKING_DIR}/1 ${TEMP_WORKING_DIR}/2 ${OUTPUT_TAXONOMY_FILE} ${OUTPUT_MAPPING_FILE}

while read species
do
	echo "Processing species: ${species}"
	if [ ! -z ${PATH_PTC_CACHE} ] && [ -d ${PATH_PTC_CACHE} ] && [ -s ${PATH_PTC_CACHE}/${species} ]; then
		echo "Found taxonomy file in cache: ${PATH_PTC_CACHE}/${species}"
		taxo=$(cat ${PATH_PTC_CACHE}/${species})
		echo ${species} ";" ${taxo} >> ${TEMP_WORKING_DIR}/taxonomy
	else
		retry_count=0

		while true; do
    		sleep ${RETRY_DELAY}

			# Redirect stdin to /dev/null to close it explicitly, otherwise the standard input of the "while read species" loop is
			# somehow deleted and it would only work for the first species in the list.
  			bash -c 'esearch -db taxonomy -query "${1}" | efetch -format xml' _ "${species}" > "${TEMP_WORKING_DIR}/${species}.xml" < /dev/null

			file_size=$(wc -c < ${TEMP_WORKING_DIR}/${species}.xml)
			if [ ${file_size} -eq 1 ]; then
				if ((retry_count >= MAX_RETRIES)); then
					echo "Max retries reached for ${species}, giving up"
					break
				else
					echo "Empty XML file for ${species}. Retrying in ${RETRY_DELAY} seconds..."
					((retry_count++))
					sleep ${RETRY_DELAY}
					continue
				fi
			fi

			taxo=$(grep '<Lineage>' ${TEMP_WORKING_DIR}/${species}.xml | sed 's/\<Lineage\>//g; s/[></]//g; s/$/;/g; s/;/;\n/g' | tac | tr '\n' ' ' | sed 's/;$//g')
			echo ${species} ";" ${taxo} >> ${TEMP_WORKING_DIR}/taxonomy

			rm ${TEMP_WORKING_DIR}/${species}.xml

			if [ ! -z ${PATH_PTC_CACHE} ] && [ -d ${PATH_PTC_CACHE} ]; then
				echo ${taxo} > ${PATH_PTC_CACHE}/${species}
				sed -i 's/ ;/;/g; s/; /;/g; s/ /_/g' ${PATH_PTC_CACHE}/${species}
				sed -i 's/+/_/g' ${PATH_PTC_CACHE}/${species}
			fi

			break
		done
	fi
done < ${TEMP_WORKING_DIR}/list_of_species

sed -i 's/ ;/;/g; s/; /;/g; s/ /_/g' ${TEMP_WORKING_DIR}/taxonomy
sed -i 's/+/_/g' ${TEMP_WORKING_DIR}/taxonomy

cp ${TEMP_WORKING_DIR}/taxonomy ${OUTPUT_TAXONOMY_FILE}
cp ${TEMP_WORKING_DIR}/sequence_to_species_mapping ${OUTPUT_MAPPING_FILE}
