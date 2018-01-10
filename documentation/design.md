# Design Decisions

## Why two separate recursion counters?

Concurrency. `lengthRecursionCount` is gets modified when an Element is
encoded using indefinite-length form, which necessitates recursively
determining the length of each nested element. `valueRecursionCount` gets
modified when the value is recursively retrieved from an element and all
of its nested subcomponents.

By splitting these in two, you can have one thread doing the first phase
of parsing and a second thread doing the second phase without mutual
interference. If none of this makes sense to you, review `concurrency.md`.

## Why not alias teletexString and videotexString to octetString, and objectDescriptor to graphicalString?

It certainly would de-duplicate code, and I would love to do that, but I cannot
guarantee that all of those types are handled the same between codecs. Also,
some of them throw type-specific error messages. It would degrade my library,
for instance, if, when decoding an invalid `TeletexString`, you received an
exception that said something about an `OCTET STRING`.

## Why not extract all of the common code into a mixin or mixin template?

I tried that and I found [a bug](https://issues.dlang.org/show_bug.cgi?id=18087)
in the process that stopped me from doing it.