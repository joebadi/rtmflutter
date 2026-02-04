#!/bin/bash

# Flutter Auto-Format Script
# Automatically fixes code formatting issues

echo "🔧 Auto-formatting Dart code..."
/opt/flutter/bin/dart format lib/ test/

echo "✓ Formatting complete!"
echo ""
echo "Run ./verify.sh to check if all issues are resolved."
