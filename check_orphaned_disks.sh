#! /bin/bash
set -e
#if [[ -z "$1" ]]; then
#  echo "Argument found"
#  az disk list --resource-group $1 > ${disks_data_$1}
#else
#  az disk list > "disks_data"
#fi

# cat disks_data_fabrik | jq '.[] | select (.ownerId != null) | {name:.accountType,diskSize:.diskSizeGb,ownerId:.ownerId}'
# cat disks_data_fabrik | jq '.[] | select (.ownerId == null) | {name:.name,owner:.ownerId,diskSizeGb:.diskSizeGb}' | jq -s '. | length'
DATA_DIR=".rundata"

if [[ -z "$1" ]]; then
  echo "Did you forget to pass the resource-group name ?" && exit 1;
fi
echo "Checking for orphaned disks in Resource Group : $1"

# Checking if previous runs data exists on disk
echo "Checking for previous run data.........."
if [[ -d "$(dirname $0)"/$DATA_DIR ]]; then
  echo "Found previous runs.. Flushing data" && rm -rf "$DATA_DIR" && mkdir "$DATA_DIR"
else
  echo "Directory does not exist....Creating" && mkdir "$DATA_DIR"
fi

az disk list --resource-group "$1" > "$DATA_DIR/disks_data"
echo "Done dumping data of disks"
echo "Number of disk records : $(jq '.[] | length' < "$DATA_DIR/disks_data")"
totalAttachedDisks=$(jq '.[] | select (.managedBy != null) | .managedBy' < "$DATA_DIR/disks_data" | jq -s '. | length')
echo "Total attached disks : $totalAttachedDisks"
totalOrphanDisks=$(jq '.[] | select ( .managedBy == null) | .name' < "$DATA_DIR/disks_data" | jq -s '. | length')
totalSizeOfOrphanDisks=$(jq '.[] | select ( .managedBy == null) | .diskSizeGb' < "$DATA_DIR/disks_data" | jq -s '. | add')
echo "FOUND a total of $(python -c "print ($totalAttachedDisks+$totalOrphanDisks)") disks out of which $totalOrphanDisks are orphan"
echo "Can reclaim $totalSizeOfOrphanDisks GB of space"
orphanedDisks=$(jq '.[] | select ( .managedBy == null) | .name' < "$DATA_DIR/disks_data" | tr -d '"')
echo $orphanedDisks
exit 0;
#Finally, deleting all such disks
for orphanDisk in $orphanedDisks
do
  echo "$finalName"
  echo "Proceeding for deletion of disk : $orphanDisk"
  echo "$orphanDisk"
  deletionResponse=$(az disk delete --name "$orphanDisk" --resource-group "$1" --yes --no-wait)
  echo "$deletionResponse"
  echo
done
#orphanedDisks=$(jq '.[] | select (.ownerId == null) | .ownerId')

