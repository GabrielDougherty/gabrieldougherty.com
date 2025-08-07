#!/bin/bash
# Performance optimization script for gabrieldougherty.com

echo "🚀 Building optimized Hugo site..."

# Clean previous build
rm -rf public/

# Build with all optimizations
hugo --minify --gc

# Calculate sizes
if [ -f "public/index.html" ]; then
    INDEX_SIZE=$(wc -c < public/index.html)
    echo "📊 Index page size: ${INDEX_SIZE} bytes"
fi

if [ -f "public/css/minimal.css" ]; then
    CSS_SIZE=$(wc -c < public/css/minimal.css)
    echo "📊 CSS file size: ${CSS_SIZE} bytes"
fi

echo "✅ Build complete! Run 'hugo server' to test locally."
echo ""
echo "🔍 To test performance:"
echo "   1. Run 'hugo server' to start development server"
echo "   2. Use Chrome DevTools Lighthouse to measure FCP"
echo "   3. Expected FCP improvement: <1.5s (from 2.4s)"
echo ""
echo "📦 Deployed optimizations:"
echo "   ✓ Inlined critical CSS"
echo "   ✓ Async loading of non-critical CSS"
echo "   ✓ DNS prefetch hints"
echo "   ✓ Minified HTML/CSS"
echo "   ✓ Optimized caching headers"
echo "   ✓ Removed render-blocking resources"
