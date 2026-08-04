# notary-chain

The part that talks to a network. **Nothing here is proven, and nothing here
needs to be**: it moves 32 bytes that the proven part computed, and if it moves
them wrongly the failure is visible immediately, because the root it publishes
either matches the one you hold or does not.

It is a separate program on purpose (round 4). One binary is the proven
computation over a document; this one is the thing with a key and a socket. A
reader can tell which is which without reading either.

## The handoff

```
notary commit --subject T --description FILE     # prints: root <hex>
notary-chain publish <hex>                       # prints: operation, level, time
notary-chain lookup <hex>                        # prints: the time the chain holds
```

The interface between the two programs is one hex string. That is the whole
format, deliberately: anything richer would be a thing to specify and get wrong.
