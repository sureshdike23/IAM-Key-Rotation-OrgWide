#!/bin/bash

cd ../lambda || exit
zip rotate_key.zip rotate_key.py
echo "✅ Lambda zipped successfully!"
