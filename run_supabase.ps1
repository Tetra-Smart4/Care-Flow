flutter clean
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

dart format lib test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter run
