#!/usr/bin/python3

import os
import argparse
import subprocess
import logging

LOGGER = logging.getLogger('application')
sh = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', '', '%')
sh.setFormatter(formatter)
LOGGER.addHandler(sh)
LOGGER.setLevel(logging.DEBUG)
LOGGER.info('Running collapse-tree.py')

ptc_version = os.getenv('PTC_VERSION', default='NA')
LOGGER.info('PTC Version: {}'.format(ptc_version))

ptc_jar_version = os.getenv('PTC_JAR_VERSION', default='NA')
LOGGER.info('PTC JAR Version: {}'.format(ptc_jar_version))

#
# Auxiliary functions
#

def run(command):
	process = subprocess.Popen(
		command,
		stdout=subprocess.PIPE,
		stderr=subprocess.STDOUT,
		shell=True,
		encoding='utf-8',
		errors='replace'
	)

	while True:
		realtime_output = process.stdout.readline()

		if realtime_output == '' and process.poll() is not None:
			break

		if realtime_output:
			print(realtime_output.strip(), flush=True)

	if process.returncode > 0:
		print('Error running command: ', command)
		os._exit(1)

#
# Program arguments
#

#
# Action to handle flags, inspired on this blog post: https://thisdataguy.com/2017/07/03/no-options-with-argparse-and-python/
# If the flag is present, then the corresponding target variable is set to True, otherwise remains as None.
#
class BooleanAction(argparse.Action):
    def __init__(self, option_strings, dest, nargs=None, **kwargs):
        super(BooleanAction, self).__init__(option_strings, dest, nargs=0, **kwargs)
 
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, True)

parser = argparse.ArgumentParser(description='Phylogenetic Tree Collapser.')

formats_list = ['newick', 'nexus', 'nexml', 'phyloxml', 'cdao']
output_type_list = ['cladogram', 'phylogram']

parser.add_argument('-i', '--input', help='input phylogenetic tree file', required=True)
parser.add_argument('-it', '--input-format', help='input phylogenetic tree file format (one of: {})'.format(', '.join(formats_list)), required=True)
parser.add_argument('-sm', '--sequence-mapping', help='input sequence mapping file (a tab-delimited file with one line for each sequence in the input tree and its corresponding species)')
parser.add_argument('-t', '--taxonomy', help='input taxonomy file (one line for each species with taxonomy terms separated by semi-colons)', default='download_taxonomy')
parser.add_argument('-ts', '--taxonomy-stop-terms', help='input taxonomy stop terms file (one line for each stop term)', default='/opt/tree-collapser/data/family_names_only')
parser.add_argument('-ft', '--flatten-taxonomy-with-stop-terms', help='flattens the taxonomy using the stop terms and uses this taxonomy to collapse the tree', dest='flatten_taxonomy_with_stop_terms', action=BooleanAction)
parser.add_argument('-o', '--output', help='output phylogenetic tree file', required=True)
parser.add_argument('-ot', '--output-type', help='type of the output phylogenetic tree (one of: {})'.format(', '.join(output_type_list)), required=True)
parser.add_argument('-ocn', '--output-collapsed-nodes', help='output tab-delimited file with the collapsed nodes', required=True)

arg = parser.parse_args()

#
# Configuration via environment variables
#

collapser_jar_path = os.getenv('COLLAPSER_JAR_PATH')
get_taxonomy_script_path = os.getenv('SCRIPT_PATH_GET_TAXONOMY')
flatten_taxonomy_script_path = os.getenv('SCRIPT_PATH_FLATTEN_TAXONOMY')

if not(arg.input_format in formats_list):
	LOGGER.error('The input format ({}) is not valid. It must be one of: {}.'.format(arg.input_format, ', '.join(formats_list)))
	os._exit(1)
	
if not(arg.output_type in output_type_list):
	LOGGER.error('The output type ({}) is not valid. It must be one of: {}.'.format(arg.output_type, ', '.join(output_type_list)))
	os._exit(1)

if not os.path.isfile(arg.input):
	LOGGER.error('The input type ({}) does not exist'.format(arg.input))
	os._exit(1)

if not(arg.input_format == 'newick'):
	LOGGER.info('The input file must be converted into Newick')
	input_file_name = os.path.basename(arg.input)
	input_file_dir = os.path.dirname(arg.input)
	output_file = arg.input + '.nwk'

	command_convert_tree = f'convert_tree.py -i {arg.input} -if {arg.input_format} -o {output_file} -of newick'

	run(command_convert_tree)
	input_file = input_file_dir + '/' + input_file_name + '.nwk'
	run('head -n 1 {} > {}'.format(input_file, input_file_dir + '/' + input_file_name + '.nwk.filtered'))
	run('mv {} {}'.format(input_file_dir + '/' + input_file_name + '.nwk.filtered', input_file))
else:
	input_file = arg.input


if arg.taxonomy == 'download_taxonomy':
	input_sequence_mapping = input_file + '.sequence_to_species_mapping'
	input_taxonomy = input_file + '.taxonomy'
	if os.path.exists(input_taxonomy) and os.path.exists(input_sequence_mapping):
		LOGGER.info('The taxonomy files already exist, re-using them:')
		LOGGER.info('Taxonomy file found: ' + input_taxonomy)
		LOGGER.info('Sequence to species mapping file found: ' + input_sequence_mapping)
	else:
		LOGGER.info('The taxonomy must be downloaded');

		command_get_taxonomy = '{} {}'.format(get_taxonomy_script_path, input_file)
		run(command_get_taxonomy)
else:
	input_sequence_mapping = arg.sequence_mapping
	input_taxonomy = arg.taxonomy


if arg.flatten_taxonomy_with_stop_terms:
	LOGGER.info('The taxonomy must be flattened with the stop terms');

	command_flatten_taxonomy = '{} {} {}'.format(flatten_taxonomy_script_path, input_taxonomy, arg.taxonomy_stop_terms)
	run(command_flatten_taxonomy)
	input_taxonomy = input_taxonomy + '.flattened_stop_terms'


command_jar = '''java -jar {} collapse-tree \
--input {} \
--sequence-mapping {} \
--taxonomy {} \
--taxonomy-stop-terms {} \
--output {} \
--output-type {} \
--output-collapsed-nodes {}'''.format(
	collapser_jar_path, 
	input_file, 
	input_sequence_mapping, 
	input_taxonomy, 
	arg.taxonomy_stop_terms, 
	arg.output, 
	arg.output_type, 
	arg.output_collapsed_nodes
)

run(command_jar)
