if which swift-format >/dev/null; then
    swift-format -m format -i -r ${PROJECT_DIR} --configuration swiftFormatConfiguration.json
else
    echo "warning: swift-format not installed"
fi
