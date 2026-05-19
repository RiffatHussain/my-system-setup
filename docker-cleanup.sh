#!/bin/bash

echo "===PRODUCTION SAFE CLEANUP==="
echo "Without even asking to DEV team"

echo "To clean the build cache"
docker buildx prune -f

echo "To clean the unused and dangling images i.e that it was not tagged or even not used by a stopped container"
docker image prune -f

echo "To clean up the volumes that was not used"
docker volume ls
echo "The above volumes are the total volumes"

echo "This command will give you the volumes that are not used and then it will provide along with the 
