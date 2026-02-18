#!/bin/bash

cd $PATH_TO_SEARCH

while read filename; do
  if find . -name "$filename" | grep -q .; then
    echo "✅ $filename found"
  else
    echo "❌ $filename NOT found"
  fi
done < ~/ids.txt