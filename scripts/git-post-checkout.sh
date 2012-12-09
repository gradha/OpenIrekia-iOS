#! /bin/sh
# Copy this script to .git/hooks/post-checkout.

# Start from the repository root.
cd ./$(git rev-parse --show-cdup)

# Run tags generation in the background
if [ -x scripts/tags.sh ]
then
	./scripts/tags.sh &
fi

# Delete .pyc files and empty directories.
#find . -name "*.pyc" -delete
#find . -type d -empty -delete
