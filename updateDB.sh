#!/bin/bash
# A handy script to update the path of your webstorm
# database so you can always view the database on the simulator your running.

# Function to find the vbvDB path
find_vbvDB() {
  xcrun simctl list devices | grep Booted | awk -F '[()]' '{print $2}' | while read -r uuid; do
    simDataPath=~/Library/Developer/CoreSimulator/Devices/"$uuid"/data/Containers/Data/Application
    for appDir in "$simDataPath"/*; do
      if [ -d "$appDir" ] && [ -f "$appDir/Library/vbvDB" ]; then
        echo "$appDir/Library/vbvDB"
      fi
    done
  done
}

# Get the database path
dbPath=$(find_vbvDB)

# Check if the database path was found
if [ -z "$dbPath" ]; then
  echo "Error: vbvDB file not found."
  exit 1
fi

# Update dataSources.xml
dataSourcesFile=".idea/dataSources.xml"

if [ -f "$dataSourcesFile" ]; then
  # Escape special characters in the path for sed
  escapedDbPath=$(echo "$dbPath" | sed 's/[\/&]/\\&/g')

  # Update the jdbc-url line
  sed -i.bak "s|<jdbc-url>.*</jdbc-url>|<jdbc-url>jdbc:sqlite:$escapedDbPath</jdbc-url>|" "$dataSourcesFile"

  echo "Updated jdbc-url in dataSources.xml with: jdbc:sqlite:$dbPath"
else
  echo "Error: dataSources.xml not found at $dataSourcesFile"
  exit 1
fi
