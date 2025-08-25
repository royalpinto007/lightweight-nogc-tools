module lightnogc.buffer;

@safe: // default safety; we use @trusted where we wrap C calls carefully

import core.stdc.stdlib : malloc, realloc, free;
import core.stdc.string : memcpy, memset;
import std.typecons : Yes, No;

struct NoGcBuffer {
    private ubyte* _ptr = null;
    private size_t _len = 0;
    private size_t _cap = 0;

    // Prevent accidental copying
    @disable this(this);

    // Move support (optional)
    this(ref return scope NoGcBuffer rhs) @nogc nothrow {
        _ptr = rhs._ptr;
        _len = rhs._len;
        _cap = rhs._cap;
        rhs._ptr = null; rhs._len = 0; rhs._cap = 0;
    }

    ~this() @nogc nothrow {
        if (_ptr) () @trusted { free(_ptr); }();
    }

    /// Create with capacity (bytes). Returns false if allocation failed.
    bool init(size_t capacity) @nogc nothrow {
        if (capacity == 0) { return true; }
        auto p = (() @trusted { return cast(ubyte*) malloc(capacity); })();
        if (p is null) return false;
        _ptr = p;
        _cap = capacity;
        _len = 0;
        return true;
    }

    /// Ensure capacity >= minCapacity (realloc on C heap). Returns false on OOM.
    bool ensureCapacity(size_t minCapacity) @nogc nothrow {
        if (minCapacity <= _cap) return true;
        size_t newCap = _cap ? _cap : 64;
        while (newCap < minCapacity) newCap *= 2;
        auto p = (() @trusted { return cast(ubyte*) realloc(_ptr, newCap); })();
        if (p is null) return false;
        _ptr = p; _cap = newCap;
        return true;
    }

    /// Append bytes (non-allocating at GC level). Returns false on OOM.
    bool append(const(ubyte)[] data) @nogc nothrow {
        if (!ensureCapacity(_len + data.length)) return false;
        (() @trusted { memcpy(_ptr + _len, data.ptr, data.length); })();
        _len += data.length;
        return true;
    }

    /// Clear length (does not free).
    void clear(bool zero = false) @nogc nothrow {
        if (zero && _ptr && _len) (() @trusted { memset(_ptr, 0, _len); })();
        _len = 0;
    }

    ubyte[] bytes() @nogc nothrow {
        return _ptr ? (() @trusted { return _ptr[0 .. _len]; })() : null;
    }

    const(ubyte)[] cbytes() const @nogc nothrow {
        return _ptr ? (() @trusted { return _ptr[0 .. _len]; })() : null;
    }

    /// Capacity/length
    size_t length() const @nogc nothrow { return _len; }
    size_t capacity() const @nogc nothrow { return _cap; }
}

@nogc @safe unittest {
    NoGcBuffer buf;
    assert(buf.init(8));

    // Avoid GC array literal in @nogc: use stack array
    ubyte[3] tmp = [1, 2, 3];
    assert(buf.append(tmp[]));

    assert(buf.length() == 3);
    assert(buf.capacity() >= 3);
    buf.clear();
    assert(buf.length() == 0);
}
