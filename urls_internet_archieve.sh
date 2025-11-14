#!/bin/bash

# Custom Internet Archive Automation Tool by ox033
# Pulls all URLs from Wayback Machine using direct API calls

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <target_domain>"
    exit 1
fi

DOMAIN="$1"
OUTPUT_DIR="custom_ia_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "[*] Starting custom Internet Archive collection for: $DOMAIN"
echo "[*] Output directory: $OUTPUT_DIR"

# Main output file
ALL_URLS_FILE="$OUTPUT_DIR/collected_urls.txt"
> "$ALL_URLS_FILE"

# Function to fetch URLs from Wayback Machine API
fetch_wayback_urls() {
    local domain="$1"
    local url="http://web.archive.org/cdx/search/cdx?url=$domain/*&output=json&fl=original&collapse=urlkey&limit=100000"
    
    echo "[*] Fetching URLs for $domain..."
    curl -s "$url" | jq -r '.[]' 2>/dev/null | grep -v "null" | grep -v "original" >> "$ALL_URLS_FILE"
}

# Main domain
fetch_wayback_urls "$DOMAIN"

# Subdomain variations
fetch_wayback_urls "*.$DOMAIN"

# Remove duplicates
sort -u "$ALL_URLS_FILE" -o "$ALL_URLS_FILE"

# Filter specific file types if needed
echo "[*] Extracting file types: pdf,doc,docx,ppt,pptx,xls,xlsx,txt,json,js,xml,csv,log,bak,sql,zip,gz,conf,config,yml,yaml,env"
grep -E '\.(pdf|doc|docx|ppt|pptx|xls|xlsx|txt|json|js|xml|csv|log|bak|sql|zip|gz|conf|config|yml|yaml|env)$' "$ALL_URLS_FILE" > "$OUTPUT_DIR/file_urls.txt"

# Check for alive endpoints
echo "[*] Checking for alive endpoints..."
if command -v httpx &> /dev/null; then
    cat "$ALL_URLS_FILE" | httpx -silent -status-code -method GET -mc 200,201,202,204,301,302,403,405,500 -cl -title -tech-detect -o "$OUTPUT_DIR/alive.txt"
else
    echo "[*] httpx not found, skipping alive check"
    cp "$ALL_URLS_FILE" "$OUTPUT_DIR/alive.txt"
fi

# Generate summary
echo "[*] Generating summary..."
cat << EOF > "$OUTPUT_DIR/SUMMARY.txt"
Custom Internet Archive Collection Summary for $DOMAIN
Generated on $(date)

Total URLs collected: $(wc -l < "$ALL_URLS_FILE")
File type URLs: $(wc -l < "$OUTPUT_DIR/file_urls.txt")

All URLs saved in: $ALL_URLS_FILE
EOF

echo "[*] Collection completed! Results saved in $OUTPUT_DIR/"
echo "[*] Total URLs collected: $(wc -l < "$ALL_URLS_FILE")"
echo "[*] All URLs saved to: $ALL_URLS_FILE"
