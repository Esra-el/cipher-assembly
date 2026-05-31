# cipher-assembly
Multi-cipher encryption/decryption engine written in RISC-V assembly
A layered encryption/decryption program written from scratch in RISC-V assembly.

## What it does
Applies five composable ciphers to a plaintext string, then decrypts by
reversing them in order:

-  A — Caesar shift cipher (with mod-26 wraparound)
-  B — keyed Vigenère-style cipher
-  C — positional encoding
-  D — complement transform
-  E — string reversal

## How it works
- Each cipher is a subroutine following proper calling conventions (saving/restoring `ra`).
- Applied ciphers are pushed to a stack, then popped in **LIFO order** for correct decryption
  (encrypt A→B→C means decrypt C→B→A).
- Implements manual modular arithmetic, register management, memory addressing,
  and system calls (`ecall`) for I/O.

## Run
Assemble and run with a RISC-V simulator (e.g. RARS or Ripes).
