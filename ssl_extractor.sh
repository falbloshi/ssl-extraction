#!/bin/bash

# FOR SOME REASON, IT SKIPS THE LAST ENTRY, 
# ADD IT MANUALLY OR ADD "EMPTY" AT THE END OF THE LIST


# check if filename given
if [ "$#" -eq 0 ]; then
    echo -e "\033[31mError\033[0m: Please provide a filename for a textfile containing the list"
    exit 1
fi

# check if the file exists
if [ ! -f "$1" ]; then
    echo -e "\033[31mError\033[0m: File '$1' not found."
    exit 1
fi

# domain list
domains=()
while IFS= read -r line; do
    #check if they are exclusively emails first 
    if [[ "${line}" == *"@"* ]]; then
        echo "Adding: $line" 
        #extract their domains next
        domains+=("$(echo "$line" | cut -d@ -f2)")
    else
        domains+=("")
    fi
done < $1

#echo "${domains[@]}"

# filtered domains list
filtered_domains=()
# excluded domain list
excluded_domains=("gmail.com" "yahoo.com" "ymail.com" "hotmail.com" "outlook.com")

# filter the domains
for domain in "${domains[@]}"; do
    
    #passes true only if the item is not inside the excluded domains
    if [[ ! " ${excluded_domains[@]} " =~ " $domain " ]]; then
        filtered_domains+=("$domain")
    else
        filtered_domains+=("")
    fi
done

# create csv file to save
working_dir="$(pwd)"
original_filename=$(basename "$1" .txt)
csv_filename="extracted_$original_filename.csv"
full_path="$working_dir/$csv_filename"
if [ -e "$full_path" ]; then
    echo "Working on: $full_path"
else 
    #adding headers
    echo "Creating: $full_path"
    echo "company,ssl-end-date" > $full_path
fi

# end date extraction
for domain in "${filtered_domains[@]}"; do
    #domain="saucedemo.com" - for testing purposes
    if [ "$domain"  == "" ]; then
            echo "_,_" >> $full_path
            continue
    fi
    #extracting the end date using ssl 
    echo "Connecting: $domain"
    cert_end_date=$(echo |  
    openssl s_client -connect "${domain}:443" -servername "${domain}" 2>/dev/null | 
    openssl x509 -noout -enddate | 
    cut -d"=" -f 2-)

    if [[ -z "$cert_end_date" ]]; then
        
        echo "Skipping \"$domain\" Invalid Website"
        echo "_,_" >> $full_path
    else
        #extracting date using 'date' command
        echo "$domain,$(date -d "$cert_end_date" +"%d/%m/%Y")" >> $full_path
    fi
done

echo "Done"