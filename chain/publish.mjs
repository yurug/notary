#!/usr/bin/env node
// notary-chain: puts a root on a chain, and reads one back.
//
// Separate from the notary by decision (round 4). Everything here is in the
// trusted base and none of it is covered by a theorem: a signer, a key, a
// network client and a contract. What keeps that acceptable is that a mistake
// here is loud rather than quiet — the root published either equals the one you
// hold or it does not, and `lookup` is how you find out without trusting this
// program at all.
//
//   notary-chain publish <root-hex>
//   notary-chain lookup  <root-hex>
//
// Configuration by environment, because a key does not belong in a repository:
//   NOTARY_RPC     an RPC endpoint          (default: shadownet)
//   NOTARY_LEDGER  the KT1 of the ledger contract
//   NOTARY_SK      the secret key, for publish only

import { TezosToolkit } from "@taquito/taquito";
import { InMemorySigner } from "@taquito/signer";

const RPC = process.env.NOTARY_RPC ?? "https://rpc.shadownet.teztnets.com";
const LEDGER = process.env.NOTARY_LEDGER;

/** `parameter bytes; storage (big_map bytes timestamp)`. The root is the key
 *  and NOW is what the chain writes beside it: the time is the protocol's,
 *  never ours. */
const LEDGER_CODE = [
  { prim: "parameter", args: [{ prim: "bytes" }] },
  { prim: "storage", args: [{ prim: "big_map", args: [{ prim: "bytes" }, { prim: "timestamp" }] }] },
  { prim: "code", args: [[
    { prim: "UNPAIR" },
    { prim: "NOW" }, { prim: "SOME" }, { prim: "SWAP" },
    { prim: "UPDATE" },
    { prim: "NIL", args: [{ prim: "operation" }] }, { prim: "PAIR" },
  ]] },
];

const die = (m) => { console.error(m); process.exit(1); };

function toolkit(withKey) {
  const t = new TezosToolkit(RPC);
  if (withKey) {
    if (!process.env.NOTARY_SK) die("E_NO_KEY: NOTARY_SK is not set.");
    t.setProvider({ signer: new InMemorySigner(process.env.NOTARY_SK) });
  }
  return t;
}

async function deploy() {
  const t = toolkit(true);
  const op = await t.contract.originate({ code: LEDGER_CODE, storage: new Map() });
  await op.confirmation(1);
  console.log(`ledger ${op.contractAddress}`);
  console.log("Set NOTARY_LEDGER to that address.");
}

async function publish(root) {
  if (!LEDGER) die("E_NO_LEDGER: NOTARY_LEDGER is not set. Run `notary-chain deploy` first.");
  const t = toolkit(true);
  const contract = await t.contract.at(LEDGER);
  const entrypoint = contract.methodsObject.default;
  if (!entrypoint) die(`E_LEDGER: ${LEDGER} has no default entrypoint.`);
  const op = await entrypoint(root).send();
  // One confirmation is inclusion. Under Tenderbake the block after it makes
  // it final, about six seconds later; a disclosure quotes the inclusion time,
  // and saying which of the three times is quoted matters more than the gap.
  await op.confirmation(1);
  console.log(`operation ${op.hash}`);
  console.log(`level     ${op.includedInBlock}`);
  console.log(`fee       ${op.fee} mutez`);
  console.log(`stamped   ${await lookupValue(root)}`);
}

async function lookupValue(root) {
  const t = toolkit(false);
  const contract = await t.contract.at(LEDGER);
  const storage = await contract.storage();
  return (await storage.get(root)) ?? "(not present)";
}

async function lookup(root) {
  if (!LEDGER) die("E_NO_LEDGER: NOTARY_LEDGER is not set.");
  const at = await lookupValue(root);
  console.log(at === "(not present)" ? `no commitment to ${root.slice(0, 12)}…` : `${at}`);
  console.log(
    "What that does not establish: that the committed text describes any\n" +
    "particular finding, or anything about the words it does not reveal.",
  );
  process.exit(at === "(not present)" ? 2 : 0);
}

const [cmd, root] = process.argv.slice(2);
const hex = /^[0-9a-f]{64}$/;
if (cmd === "deploy") await deploy();
else if (cmd === "publish" && hex.test(root ?? "")) await publish(root);
else if (cmd === "lookup" && hex.test(root ?? "")) await lookup(root);
else die("usage: notary-chain deploy | publish <root-hex> | lookup <root-hex>");
