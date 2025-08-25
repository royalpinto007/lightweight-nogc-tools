module lightnogc.string_ops;

@safe:

/// Non-allocating startsWith / endsWith for string-like slices.
bool startsWith(const(char)[] s, const(char)[] prefix) @nogc nothrow {
    if (prefix.length > s.length) return false;
    foreach (i; 0 .. prefix.length)
        if (s[i] != prefix[i]) return false;
    return true;
}

bool endsWith(const(char)[] s, const(char)[] suffix) @nogc nothrow {
    if (suffix.length > s.length) return false;
    auto off = s.length - suffix.length;
    foreach (i; 0 .. suffix.length)
        if (s[off + i] != suffix[i]) return false;
    return true;
}

/// Lowercase ASCII in-place on a mutable buffer (no allocation).
void toLowerAsciiInPlace(char[] s) @nogc nothrow {
    foreach (ref c; s) {
        if (c >= 'A' && c <= 'Z') c = cast(char)(c + 32);
    }
}

@nogc @safe unittest {
    assert(startsWith("Hello", "He"));
    assert(!startsWith("He", "Hello"));
    assert(endsWith("cargo", "go"));

    // Avoid .dup in @nogc: use stack buffer
    char[5] buf = ['A','B','C','d','E'];
    toLowerAsciiInPlace(buf[]);
    assert(buf[] == "abcde");
}