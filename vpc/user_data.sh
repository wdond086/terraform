#!/bin/bash
echo "Hello, World from public instance ${count.index + 1}" > index.html
python3 -m http.server 8080