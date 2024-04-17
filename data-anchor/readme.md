## A Note on Data Anchoring

**Data Anchoring**, also known as Digital Archiving or Public Timestamping[^1], involves writing a cryptographic hash to immutable storage. Public blockchains present an ideal use case for this type of activity as the distributed database ensures data replication and censorship resistance, and the public nature makes verification quick and efficient.

[^1]: Haber, S., & Stornetta, W. S. (1991). How to Time-Stamp a Digital Document. In A. J. Menezes & S. A. Vanstone (Eds.), Advances in Cryptology-CRYPTO '90 (pp. 437–455). Springer. [DOI: 10.1007/3-540-38424-3_32](https://doi.org/10.1007/3-540-38424-3_32)

The work has been anchored to popular blockchains by including the hash in a transaction in the appropriate style.

The `SHA256` hash of version 1 of this document is:
```
9885dee02e36e2e4bbf808093364f2dafcc284a119f280417025e64fb5b47215
```

and can be verified by downloading the PDF file from [GitHub](https://github.com/millecodex/phd/blob/main/thesis/Nijsse-PhD-anchored.pdf), computing the SHA256 hash, for example:
```
$ shasum -a 256 Nijsse-PhD-anchored.pdf
```

and comparing the hashed output to the public value found in the blockchain. Any update to a pdf, such as including a transaction hash or block number, will invalidate the hash, so to avoid this issue, a live-update must be provided, exclusive of the original hash creation.

### Bitcoin

The `OP_RETURN` script opcode in a Bitcoin transaction marks the transaction outputs as unspendable, or specifically as a UTXO of type `nulldata`. Thus, any data in the field terminates the UTXO chain and can be used to burn bitcoin, or, as in this case, store 80 bytes of arbitrary data. Using `OP_RETURN` is considered more polite than writing data to the pay-to-public-key-hash (p2pkh) output, as it is difficult to distinguish from a real public-key-hash, and so must be stored by all nodes.[^2] `OP_RETURN` data can optionally be pruned by nodes to save storage.

[^2]: Bartoletti, M., & Pompianu, L. (2017). An analysis of Bitcoin OP_RETURN metadata. [arXiv: 1702.01024](https://arxiv.org/abs/1702.01024)

The [transaction](https://mempool.space/tx/76adf298dcd1d981fde6a846956ea86ad42cc26f8caba09c1ced920c943c4e04) in block `838705` contains the following transaction output, partially shown in `JSON`, where part of the `OP_RETURN` is:
```
"outputs": [
  {
    "address": null,
    "pkscript": "6a209885dee02e36e2e4bbf808093364f2dafcc284a119f280417025e64fb5b47215",
    "value": 0,
    "spent": false,
    "spender": null
  }
]
```

The end of the `pkscript` value matches the `SHA256` output.

### Ethereum

Smart contract functionality allows for more versatile storage in Ethereum. One method is to deploy a contract that contains some data that can be retrieved later by calling the contract. An alternate method is to use the logging capability in the `data` field of a transaction that will write log data to the transaction receipt.

A [contract](https://etherscan.io/address/0x975a313f03a56d232d9353830d8930481cff5e1f) is deployed to Ethereum at:
```
0x975A313f03a56d232D9353830D8930481CFf5e1f
```

which accepts a 32 byte hash and a message:
```
addHash(bytes32 _hash, string calldata _message)
```

In block 19666573, the [transaction](https://etherscan.io/tx/0x847a818aec4827fc91260c6d1c3d85f53bb028381c48c2457c1bdfb82d5c8f93) contains the hash above (prepended with `0x`) and the message: 'Nijsse-PhD-data-anchor'.
