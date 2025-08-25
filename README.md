# lightweight-nogc-tools

Small, practical helpers usable in `@nogc` code:

- **NoGcBuffer** – a byte buffer on the C heap (malloc/realloc/free)
- **NoGcArray!T** – a typed dynamic array on the C heap
- **string_ops** – non-allocating helpers like `startsWith`, `endsWith`, and ASCII lowercase in-place


## Why?

This library is meant to practice and demonstrate GC-free patterns in D.  
It provides small, reusable pieces that avoid the garbage collector and work with the C heap directly.  

Useful if you want to write code that is `@nogc` and predictable in memory usage.

## Installation

Add this to your `dub.sdl`:

```sdl
dependency "lightweight-nogc-tools" version="~>0.1.0"
````

## Quick Example

```d
import lightnogc: NoGcBuffer, NoGcArray, toLowerAsciiInPlace, startsWith;

@nogc nothrow @safe:
void demo() {
    // --- NoGcBuffer (bytes)
    NoGcBuffer buf;
    assert(buf.init(64));
    assert(buf.append(cast(const ubyte[])"hello"));
    assert(buf.length() == 5);

    // --- NoGcArray!T (typed array)
    NoGcArray!int arr;
    assert(arr.init(4));
    assert(arr.push(42));
    assert(arr.slice()[0] == 42);

    // --- String ops (in-place lowercase)
    char[] s = "ABC".dup; // dup allocates once in test, funcs themselves are @nogc
    toLowerAsciiInPlace(s);
    assert(startsWith(s, "ab"));
}
```

## Features

* `NoGcBuffer`

  * Append bytes without GC allocation.
  * Resizes using `realloc` on the C heap.
  * Provides mutable and const slice views.

* `NoGcArray!T`

  * GC-free array of any type `T`.
  * Push values dynamically, with exponential resize on the C heap.
  * Provides safe slices for iteration.

* `string_ops`

  * `startsWith` and `endsWith` checks without allocation.
  * `toLowerAsciiInPlace` to lowercase a buffer in-place.

## Notes

* Uses **C heap memory** (`malloc`, `realloc`, `free`); no GC allocations inside the library functions.
* Functions are annotated with `@nogc` and `nothrow` wherever possible.
* Use `.clear()` or destructors to release memory.
* Some examples/tests use `.dup` just for setup convenience.
