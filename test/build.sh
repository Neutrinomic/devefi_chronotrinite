#!/bin/sh

# Ensure the build directory exists
mkdir -p ./build

# Export PATH or any other environment variables if necessary to ensure commands are found
# export PATH="/path/to/your/commands:$PATH"

# Use GNU Parallel to process each *.test.mo file
#   `NODE_OPTIONS="--no-deprecation" npx mocv bin`/moc `mops sources` --idl --hide-warnings --error-detail 0 -o "./build/${base_name}.wasm" --idl {} 1>/dev/null 2>/dev/null &&
mocv use 0.13.2 # Only for the tests

# Extract the base name without the directory and .test.mo extension


# Run moc to produce the wasm file. Adjust the moc command as necessary.
`NODE_OPTIONS="--no-deprecation" npx mocv bin`/moc `mops sources` --idl --hide-warnings -o "./build/slice.wasm" --idl ../src/canister/slice.mo &&

# Assuming main.did is produced by the above moc command and matches the base name.
# Generate JavaScript bindings
didc bind "./build/slice.did" --target js > "./build/slice.idl.js" &&

# Generate TypeScript bindings
didc bind "./build/slice.did" --target ts > "./build/slice.idl.d.ts" ;

echo "Finished processing slice"



# Run moc to produce the wasm file. Adjust the moc command as necessary.
`NODE_OPTIONS="--no-deprecation" npx mocv bin`/moc `mops sources` --idl --hide-warnings -o "./build/router.wasm" --idl ../src/canister/router.mo &&

# Assuming main.did is produced by the above moc command and matches the base name.
# Generate JavaScript bindings
didc bind "./build/router.did" --target js > "./build/router.idl.js" &&

# Generate TypeScript bindings
didc bind "./build/router.did" --target ts > "./build/router.idl.d.ts" ;

echo "Finished processing router"


# Run moc to produce the wasm file. Adjust the moc command as necessary.
`NODE_OPTIONS="--no-deprecation" npx mocv bin`/moc `mops sources` --idl --hide-warnings -o "./build/client.wasm" --idl ../src/canister/client.mo &&

# Assuming main.did is produced by the above moc command and matches the base name.
# Generate JavaScript bindings
didc bind "./build/client.did" --target js > "./build/client.idl.js" &&

# Generate TypeScript bindings
didc bind "./build/client.did" --target ts > "./build/client.idl.d.ts" ;

echo "Finished processing client"


# Note: GNU Parallel executes each job in a separate shell instance,
# so you might need to ensure that all necessary environment variables are exported or defined within the parallel command block.