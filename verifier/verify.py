#!/usr/bin/env python3
"""An independent verifier for a notary disclosure.

Written from kb/format.md alone, in a different language, sharing no line with
the tool that produced the disclosure. That is the point: a guarantee only our
code can check is not a guarantee anyone else can rely on.

An honest note on what this is worth. The same person wrote the format and this
file, so agreement between them tests whether the format is *precise*, not
whether it is independently reproducible. A stranger's implementation is still
owed. What this does establish is that the format document is complete enough
to work from without opening the OCaml or the Rocq.

    usage: verify.py disclosure.json <root-hex>
    exit 0 compatible, 2 not compatible, 1 error.
"""

import hashlib
import json
import struct
import sys


def leaf(i: int, word: str, salt: bytes) -> bytes:
    """The salt is what stops a hidden leaf's hash being guessed from a
    dictionary. Salts for revealed words travel in the disclosure; the ones for
    hidden words never leave the committer."""
    return hashlib.sha256(
        b"\x00" + struct.pack(">I", i) + salt + word.encode("utf-8")
    ).digest()


def node(a: bytes, b: bytes) -> bytes:
    return hashlib.sha256(b"\x01" + a + b).digest()


def count(n: int, r: bytes) -> bytes:
    return hashlib.sha256(b"\x02" + struct.pack(">I", n) + r).digest()


def fold(level: list[bytes]) -> bytes:
    while len(level) > 1:
        # An odd level duplicates its last node.
        nxt = []
        for i in range(0, len(level), 2):
            left = level[i]
            right = level[i + 1] if i + 1 < len(level) else left
            nxt.append(node(left, right))
        level = nxt
    return level[0]


def verify(d: dict, root_hex: str) -> bool:
    proof = [bytes.fromhex(h) for h in d["proof"]]
    if len(proof) != d["leaf_count"]:
        return False
    for i, word, salt_hex in d["revealed"]:
        if not (0 <= i < len(proof)) or proof[i] != leaf(i, word, bytes.fromhex(salt_hex)):
            return False
    return count(d["leaf_count"], fold(proof)).hex() == root_hex


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: verify.py disclosure.json <root-hex>", file=sys.stderr)
        sys.exit(1)
    with open(sys.argv[1], encoding="utf-8") as fh:
        disclosure = json.load(fh)
    ok = verify(disclosure, sys.argv[2])
    print(
        "compatible: this redaction is a redaction of the text committed to by "
        f"{sys.argv[2][:12]}…"
        if ok
        else f"not compatible with {sys.argv[2][:12]}…"
    )
    print(
        "What that does not establish: that the text describes your finding,\n"
        "that whoever committed it understood it, or anything about the parts\n"
        "they did not reveal."
    )
    sys.exit(0 if ok else 2)
