#!/bin/bash

# Initialize variables
process_all=false
input_file=""
asr_tree_file=""
summary_file="summary_statistics.txt"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -alllist)
            process_all=true
            shift
            ;;
        *)
            if [ -z "$input_file" ]; then
                input_file="$1"
            elif [ -z "$asr_tree_file" ]; then
                asr_tree_file="$1"
            else
                echo "Error: Too many arguments."
                echo "Usage: $0 [-alllist] <input_file.tab> <asr_tree_file.tre>"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if required arguments are provided
if [ -z "$input_file" ] || [ -z "$asr_tree_file" ]; then
    echo "Usage: $0 [-alllist] <input_file.tab> <asr_tree_file.tre>"
    exit 1
fi

# Check if input files exist
if [ ! -f "$input_file" ] || [ ! -f "$asr_tree_file" ]; then
    echo "Error: Input file or ASR tree file not found."
    exit 1
fi

# Clear or create the summary file
> "$summary_file"

# Read the column headers
IFS=$'\t' read -ra headers <<< "$(head -n 1 "$input_file")"

# Process each column except the first one (orthogroupsID)
for ((i=1; i<${#headers[@]}; i++)); do
    column_name="${headers[$i]}"
    
    # Skip columns starting with < if -alllist is not set
    if [[ "$column_name" == "<"* ]] && [ "$process_all" = false ]; then
        echo "Skipping column: $column_name"
        continue
    fi
    
    echo "Processing column: $column_name"
    
    # Extract positive values to .expanded file
    awk -v col=$((i+1)) 'NR==1{print $1"\t"$col; next} $col > 0 {print $1 "\t" $col}' "$input_file" > "${column_name}.expanded"
    
    # Extract negative values to .contracted file
    awk -v col=$((i+1)) 'NR==1{print $1"\t"$col} $col < 0 {print $1 "\t" $col}' "$input_file" > "${column_name}.contracted"
    
    # Remove the first line from generated files
    sed -i '1d' "${column_name}.expanded" "${column_name}.contracted"
    
    # Extract species name without <number>
    species_name=$(echo "$column_name" | sed 's/<[0-9]*>//g')
    
    # If species_name is empty, use the original column_name
    if [ -z "$species_name" ]; then
        species_name="${column_name//[<>]/}"  # Remove < and >
    fi
    
    # Extract significant trees
    grep "${column_name}\*" "$asr_tree_file" > "${species_name}_significant_trees.tre"
    
    # Extract significant OGIDs
    grep -E -o "OG[0-9]+" "${species_name}_significant_trees.tre" > "${species_name}_significant.ogs"
    
    # Extract significant contracted OGIDs
    grep -f "${species_name}_significant.ogs" "${column_name}.contracted" | cut -f1 > "${species_name}.contracted.significant"
    
    # Extract significant expanded OGIDs
    grep -f "${species_name}_significant.ogs" "${column_name}.expanded" | cut -f1 > "${species_name}.expanded.significant"
    
    # Count lines in files
    expanded_count=$(wc -l < "${column_name}.expanded")
    contracted_count=$(wc -l < "${column_name}.contracted")
    expanded_sig_count=$(wc -l < "${species_name}.expanded.significant")
    contracted_sig_count=$(wc -l < "${species_name}.contracted.significant")
    
    # Add statistics to summary file
    echo "${column_name} +${expanded_count} -${contracted_count} +${expanded_sig_count}* -${contracted_sig_count}*" >> "$summary_file"
    
    echo "Completed processing for $species_name (original column: $column_name)"
done

echo "Processing complete. Summary statistics saved in $summary_file"
