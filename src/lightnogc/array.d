module lightnogc.array;

@safe:

import core.stdc.stdlib : malloc, realloc, free;

/// A GC-free, typed dynamic array that stores elements on the C heap.
/// Uses malloc/realloc/free under the hood.
/// All public methods are `@nogc` and `nothrow` where possible.
struct NoGcArray(T)
{
    private T* _ptr = null;
    private size_t _len = 0;
    private size_t _cap = 0;

    // Prevent accidental copying
    @disable this(this);

    // Move constructor
    this(ref return scope NoGcArray rhs) @nogc nothrow
    {
        _ptr = rhs._ptr;
        _len = rhs._len;
        _cap = rhs._cap;
        rhs._ptr = null;
        rhs._len = 0;
        rhs._cap = 0;
    }

    // Destructor
    ~this() @nogc nothrow
    {
        if (_ptr) (() @trusted { free(_ptr); })();
    }

    /// Initialize storage with a given capacity (elements).
    /// Returns false on OOM.
    bool init(size_t capacity) @nogc nothrow
    {
        if (capacity == 0)
            return true;
        const bytes = capacity * T.sizeof;
        auto p = (() @trusted { return cast(T*) malloc(bytes); })();
        if (p is null)
            return false;
        _ptr = p;
        _cap = capacity;
        _len = 0;
        return true;
    }

    /// Ensure capacity is at least minCapacity (elements).
    /// Returns false on OOM.
    bool ensureCapacity(size_t minCapacity) @nogc nothrow
    {
        if (minCapacity <= _cap)
            return true;
        size_t newCap = _cap ? _cap : 16;
        while (newCap < minCapacity)
            newCap *= 2;
        const bytes = newCap * T.sizeof;
        auto p = (() @trusted { return cast(T*) realloc(_ptr, bytes); })();
        if (p is null)
            return false;
        _ptr = p;
        _cap = newCap;
        return true;
    }

    /// Push one element. Returns false on OOM.
    bool push(T value) @nogc nothrow
    {
        if (!ensureCapacity(_len + 1))
            return false;
        // pointer indexing is @system → trusted block
        (() @trusted { _ptr[_len++] = value; })();
        return true;
    }

    /// Slice view over current elements (mutable).
    T[] slice() @nogc nothrow
    {
        return _ptr ? (() @trusted { return _ptr[0 .. _len]; })() : null;
    }

    /// Slice view over current elements (const).
    const(T)[] cslice() const @nogc nothrow
    {
        return _ptr ? (() @trusted { return _ptr[0 .. _len]; })() : null;
    }

    /// Current number of elements.
    @property size_t length() const @nogc nothrow { return _len; }

    /// Current capacity (in elements).
    @property size_t capacity() const @nogc nothrow { return _cap; }
}

@nogc @safe unittest
{
    NoGcArray!int arr;
    assert(arr.init(2));
    assert(arr.push(10));
    assert(arr.push(20));

    // Both forms are okay:
    assert(arr.length == 2);
    assert(arr.length() == 2);

    auto s = arr.slice();
    assert(s.length == 2);
    assert(s[0] == 10 && s[1] == 20);

    // Capacity should be >= length
    assert(arr.capacity >= arr.length);
}
