#!/bin/bash

PHASE1=./pot10_final.ptau
BUILD_DIR=./build/draw
CIRCUIT_DIR=./circuits
CIRCUIT_NAME=("draw" "draw_2")
CONTRACTS_DIR=./src

if [ -f "$PHASE1" ]; then
    echo "Found Phase 1 ptau file"
else
    echo "No Phase 1 ptau file found. Exiting..."
    exit 1
fi

rm -rf "$BUILD_DIR"

if [ ! -d "$BUILD_DIR" ]; then
    echo "No build directory found. Creating build directory..."
    mkdir -p "$BUILD_DIR"
fi

for circuit_name in "${CIRCUIT_NAME[@]}"
do
  echo "$circuit_name"
  echo "****COMPILING CIRCUIT****"
  start=`date +%s`
  circom "$CIRCUIT_DIR"/"$circuit_name"/"$circuit_name".circom --r1cs --wasm --sym --c --wat --output "$BUILD_DIR"
  end=`date +%s`
  echo "DONE ($((end-start))s)"

  echo "****GENERATING WITNESS FOR SAMPLE INPUT****"
  start=`date +%s`
  node "$BUILD_DIR"/"$circuit_name"_js/generate_witness.js "$BUILD_DIR"/"$circuit_name"_js/"$circuit_name".wasm "$CIRCUIT_DIR"/"$circuit_name"/input.json "$BUILD_DIR"/witness.wtns
  end=`date +%s`
  echo "DONE ($((end-start))s)"

  echo "****GENERATING ZKEY 0****"
  start=`date +%s`
  npx snarkjs groth16 setup "$BUILD_DIR"/"$circuit_name".r1cs "$PHASE1" "$BUILD_DIR"/"$circuit_name"_0.zkey
  end=`date +%s`
  echo "DONE ($((end-start))s)"

  echo "****CONTRIBUTE TO THE PHASE 2 CEREMONY****"
  start=`date +%s`
  echo "test" | npx snarkjs zkey contribute "$BUILD_DIR"/"$circuit_name"_0.zkey "$BUILD_DIR"/"$circuit_name"_1.zkey --name="1st Contributor Name"
  end=`date +%s`
  echo "DONE ($((end-start))s)"

  echo "****GENERATING FINAL ZKEY****"
  start=`date +%s`
  npx snarkjs zkey beacon "$BUILD_DIR"/"$circuit_name"_1.zkey "$BUILD_DIR"/"$circuit_name".zkey 0102030405060708090a0b0c0d0e0f101112231415161718221a1b1c1d1e1f 10 -n="Final Beacon phase2"
  end=`date +%s`
  echo "DONE ($((end-start))s)"

  echo "****VERIFYING FINAL ZKEY****"
  start=`date +%s`
  npx snarkjs zkey verify "$BUILD_DIR"/"$circuit_name".r1cs "$PHASE1" "$BUILD_DIR"/"$circuit_name".zkey
  end=`date +%s`
  echo "DONE ($((end-start))s)"

  echo "****EXPORTING VKEY****"
  start=`date +%s`
  npx snarkjs zkey export verificationkey "$BUILD_DIR"/"$circuit_name".zkey "$BUILD_DIR"/vkey.json
  end=`date +%s`
  echo "DONE ($((end-start))s)"

  echo "****GENERATING PROOF FOR SAMPLE INPUT****"
  start=`date +%s`
  npx snarkjs groth16 prove "$BUILD_DIR"/"$circuit_name".zkey "$BUILD_DIR"/witness.wtns "$BUILD_DIR"/proof.json "$BUILD_DIR"/public.json
  end=`date +%s`
  echo "DONE ($((end-start))s)"

  echo "****VERIFYING PROOF FOR SAMPLE INPUT****"
  start=`date +%s`
  npx snarkjs groth16 verify "$BUILD_DIR"/vkey.json "$BUILD_DIR"/public.json "$BUILD_DIR"/proof.json
  end=`date +%s`
  echo "DONE ($((end-start))s)"

  echo "****TURNING INTO CONTRACT****"
  start=`date +%s`
  npx snarkjs zkey export solidityverifier "$BUILD_DIR"/"$circuit_name".zkey "$CONTRACTS_DIR"/"$circuit_name".sol
  end=`date +%s`
  echo "DONE ($((end-start))s)"
done

