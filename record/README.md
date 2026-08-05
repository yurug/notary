# The recorded run, 4-5 August 2026

Fifteen takes, one per development cycle, exported from the recorder's local
store through its sanitisation gate. Each directory holds four files as they
were recorded: `goal` (written before the work), `diff` (the working-tree
change the cycle produced), `judgement.txt` (written after it), and
`take.json` (the three together). Takes 1-12 are the 4 August run the essay
walks; takes 13-15 are the multiproof lap (round 7), added 5 August. The
commit messages on `main` were rewritten after the 4 August run to describe the
changes; the tag `recorded-run-2026-08-04` preserves that chain as it stood.

| # | Take | Opened | Outcome | Goal |
|---|------|--------|---------|------|
| 1 | [`01KZ5PD3TK…`](01KZ5PD3TKDVDHZENN816R9A3N/) | 2026-08-04 06:12 | shipped | cycle 1: define the product and draw the certified boundary |
| 2 | [`01KZ5Q3E30…`](01KZ5Q3E30RKHYYSKN8KG061QG/) | 2026-08-04 06:24 | shipped | cycle 2: state the theorem before proving it, and find out whether it is readable |
| 3 | [`01KZ5QGYET…`](01KZ5QGYET48JEMDQR03AEQGVC/) | 2026-08-04 06:31 | shipped | cycle 3: prove the obligation, or find out what is wrong with it |
| 4 | [`01KZ5QRF63…`](01KZ5QRF63JMKPB3XTB77TYSNQ/) | 2026-08-04 06:35 | shipped | cycle 3b: discharge soundness and completeness on a concrete verifier and prover |
| 5 | [`01KZ5T6EV1…`](01KZ5T6EV1M2YTRDE9GQYS8ERP/) | 2026-08-04 07:18 | failed | cycle 3c: discharge fold_determines_leaves, budget four attempts, then stop and change the goal |
| 6 | [`01KZ5VAQ0N…`](01KZ5VAQ0NVV6JFGZZMQJ3YKSP/) | 2026-08-04 07:38 | shipped | cycle 3d: prove fold injectivity at equal length, budget three attempts, then route the length question to a decision round |
| 7 | [`01KZ611JQ9…`](01KZ611JQ9VB5WBTWR9FXCAB22/) | 2026-08-04 09:18 | shipped | cycle 3e: bind the length into the root and close soundness with no axiom, budget four attempts |
| 8 | [`01KZ65G242…`](01KZ65G2423BTWNB97BTSXB78Y/) | 2026-08-04 10:35 | shipped | cycle 4: extract the core to OCaml and find out what the boundary really costs |
| 9 | [`01KZ6AGDVK…`](01KZ6AGDVKC1PA5WVD3T2EQEEW/) | 2026-08-04 12:03 | shipped | cycle 5: the shell, from a real SHA-256 to a working command line |
| 10 | [`01KZ6BB1V9…`](01KZ6BB1V9BP5YPXE1P1PJC0B2/) | 2026-08-04 12:17 | shipped | cycle 6: the reporter's walk, and find out what they are missing |
| 11 | [`01KZ6EPTQE…`](01KZ6EPTQEX0Y07H0R198ZKS5J/) | 2026-08-04 13:16 | shipped | cycle 7: exercise the left half of the ring - onboarding, a decision with a stated reason, a real change, and the alignment checkpoint |
| 12 | [`01KZ6ZPBVN…`](01KZ6ZPBVNCQFTQPD854CJGNXP/) | 2026-08-04 18:13 | shipped | cycle 8: salt every leaf, so a redaction hides something, and check the attack no longer works |
| 13 | [`01KZ9M8G2G…`](01KZ9M8G2G1NNT5JEC9QFTVCSH/) | 2026-08-05 18:51 | shipped | cycle 9: subtree redaction (the multiproof): design round first, deciding the proof shape and format compatibility, the disclosure policy on gap structure, and the Rocq proof strategy; no code before the round closes |
| 14 | [`01KZ9MMM6D…`](01KZ9MMM6DNHJM0HKKJ7J9X1YA/) | 2026-08-05 18:58 | shipped | cycle 9b: define the multiproof and reprove the core: shape-directed proof structure, verify over it, soundness and completeness closed under the global context with no axioms, budget six attempts for the two theorems together |
| 15 | [`01KZ9PHQ92…`](01KZ9PHQ922M63PS0QJ4EA2389/) | 2026-08-05 19:31 | shipped | cycle 9c: ship the multiproof end to end: re-extract the core, rewire the OCaml shell to build and verify pruned trees, retire the v1 full-list disclosure on the wire, update format.md and the Python verifier, all tests green |

One take is `failed`, and it is kept: the budget it declared before its first
attempt ran out, and the rule was to stop rather than continue until something
passed. No take was re-run.
