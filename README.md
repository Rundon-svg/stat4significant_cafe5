backup: Extract significant OGIDs (p<0.05) for species/nodes from CAFE5 result files and perform statistics.

Usage: Run the following bash command:

bash

.sh XXX_change.tab XXX_asr.tre -alllist

For each species and node, 6 files will be generated, including "contracted" and "expanded":
Files containing OGIDs with changes and the number of changes.
Files containing significant OGIDs (p<0.05) and their tree file.

Additionally, a file named summary_statistics.txt will be generated at the end, summarizing the number of OGIDs with changes for each species and node.

If the -alllist option is not provided, the script will only process species nodes.
Since there are many result files, it is recommended to create a new directory containing the XXX_change.tab and XXX_asr.tre files.

Code Source: The related commands and logic are referenced from (https://yanzhongsino.github.io/2021/10/29/bioinfo_gene.family_CAFE5/).
