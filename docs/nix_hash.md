### Why every `/nix/store` path starts with a funny‐looking hash

```
/nix/store/1v3d2qj7k6vvkr7mprqnlk4p4yyk2r7d-python3-3.10.12
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

| What it is                                 | Key points                                                                                                                                                                                                                                                                                                                             |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A deterministic ID**                     | The 32-character string is a base-32 encoding of the first 160 bits of a SHA-256 hash (older Nix once used MD5, which is why you sometimes still hear that).                                                                                                                                                                           |
| **What gets hashed**                       | Nix hashes a *derivation file* (.drv) that records:<br>• the exact build script<br>• all compile flags and environment variables<br>• absolute paths of every input in `/nix/store`.<br>This recipe is serialized to a Nix archive (NAR) and then hashed.                                                                              |
| **Why 160 bits, not the full 256**         | 160 bits keeps paths short enough to stay under Unix’s 255-byte filename limit while still leaving the chance of a collision astronomically low.                                                                                                                                                                                       |
| **What it guarantees**                     | If any dependency, flag, or patch changes, the hash changes, so the output gets a new, unique path. That means:<br>• builds are *pure* (no accidental reuse of impure results)<br>• multiple versions can coexist side-by-side<br>• Nix can treat packages like immutable content-addressed blobs for caching and binary substituters. |
| **Special case: fixed-output derivations** | For things fetched from the network (tarballs, git clones) you declare the expected content hash explicitly. That hash goes in the metadata, but the store path still starts with the derivation hash that points to the fetcher instructions.                                                                                         |

#### Practical takeaway

You never have to compute or remember these hashes. Nix does it so that:

* every build is reproducible and referentially transparent
* the package manager can tell with one look at the path exactly which build recipe produced the files

Think of the hash as the package’s fingerprint: change even a single bit of the recipe or its inputs and you get an entirely new fingerprint, guaranteeing there is no accidental overlap in the store.
