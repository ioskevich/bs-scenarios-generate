#/usr/local/bin/bash
source config.sh

# Temp file name for jq
WORK_FILE=$BACKSTOP_CONFIG_TPL_FILE.tmp
# Copy source config to tmp file
cp $BACKSTOP_CONFIG_TPL_FILE $WORK_FILE

# Get scenario template
SCENARIO_TPL=$(jq '.scenarios[0]' $WORK_FILE)
SCENARIOS=$(jq --null-input '{"scenarios":[]}')

# Cleanup file with paths to test
echo "Removing duplicates from the file with paths to test..."
sort -f crawler/paths | uniq > $PATHS_FILE

while IFS= read -r PATH_TO_TEST
do
	echo "Generating backstop scenario for $PATH_TO_TEST..."
	# Generate scenario for the path
	SCENARIO_TO_ADD=$(jq \
	--arg test_domain "$TEST_DOMAIN" \
	--arg ref_domain "$REF_DOMAIN" \
	--arg path_to_test "$PATH_TO_TEST" \
	'.url |= $test_domain + $path_to_test | .referenceUrl |= $ref_domain + $path_to_test | .label |= $path_to_test' \
	<<< $SCENARIO_TPL)
	
	# Insert scenario into scenarios array.
	SCENARIOS=$(jq --argjson scenario_to_add "$SCENARIO_TO_ADD" \
	'.scenarios[.scenarios| length] |= . + $scenario_to_add' <<< $SCENARIOS)

done < $PATHS_FILE

echo "Writing scenarios to $BACKSTOP_CONFIG_FILE..."
jq --argjson scenarios "$SCENARIOS" '. |= . + $scenarios' $WORK_FILE > $BACKSTOP_CONFIG_FILE

echo "Removing tmp file ($WORK_FILE)..."
rm $WORK_FILE

