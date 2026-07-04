// SPDX-License-Identifier: MIT
/++
    Opaque handle id types for Box2D objects.

    These ids are handles to internal Box2D objects and should be treated as
    opaque values passed by value. All ids are considered null when zero
    initialized (D default initialization yields a null id).

    Translated from `box2d/id.h`.
+/
module box2d.id;

@safe nothrow @nogc:

/// World id references a world instance. Treat as an opaque handle.
struct b2WorldId
{
    ushort index1;
    ushort generation;
}

/// Body id references a body instance. Treat as an opaque handle.
struct b2BodyId
{
    int index1;
    ushort world0;
    ushort generation;
}

/// Shape id references a shape instance. Treat as an opaque handle.
struct b2ShapeId
{
    int index1;
    ushort world0;
    ushort generation;
}

/// Chain id references a chain instance. Treat as an opaque handle.
struct b2ChainId
{
    int index1;
    ushort world0;
    ushort generation;
}

/// Joint id references a joint instance. Treat as an opaque handle.
struct b2JointId
{
    int index1;
    ushort world0;
    ushort generation;
}

/// Contact id references a contact instance. Treat as an opaque handle.
struct b2ContactId
{
    int index1;
    ushort world0;
    short padding;
    uint generation;
}

/// Null ids. Zero initialization also yields a null id.
enum b2WorldId b2_nullWorldId = b2WorldId.init;
enum b2BodyId b2_nullBodyId = b2BodyId.init; /// ditto
enum b2ShapeId b2_nullShapeId = b2ShapeId.init; /// ditto
enum b2ChainId b2_nullChainId = b2ChainId.init; /// ditto
enum b2JointId b2_nullJointId = b2JointId.init; /// ditto
enum b2ContactId b2_nullContactId = b2ContactId.init; /// ditto

/// True if the id is null (any id type).
pragma(inline, true) bool B2_IS_NULL(Id)(Id id) pure
{
    return id.index1 == 0;
}

/// True if the id is non-null (any id type).
pragma(inline, true) bool B2_IS_NON_NULL(Id)(Id id) pure
{
    return id.index1 != 0;
}

/// Compare two ids for equality. Does not work for `b2WorldId`. Do not mix types.
pragma(inline, true) bool B2_ID_EQUALS(Id)(Id id1, Id id2) pure
{
    return id1.index1 == id2.index1 && id1.world0 == id2.world0 && id1.generation == id2.generation;
}

/// Store a world id into a `uint`.
pragma(inline, true) uint b2StoreWorldId(b2WorldId id) pure
{
    return (cast(uint) id.index1 << 16) | cast(uint) id.generation;
}

/// Load a `uint` into a world id.
pragma(inline, true) b2WorldId b2LoadWorldId(uint x) pure
{
    return b2WorldId(cast(ushort)(x >> 16), cast(ushort) x);
}

/// Store a body id into a `ulong`.
pragma(inline, true) ulong b2StoreBodyId(b2BodyId id) pure
{
    return (cast(ulong) id.index1 << 32) | (cast(ulong) id.world0) << 16 | cast(ulong) id.generation;
}

/// Load a `ulong` into a body id.
pragma(inline, true) b2BodyId b2LoadBodyId(ulong x) pure
{
    return b2BodyId(cast(int)(x >> 32), cast(ushort)(x >> 16), cast(ushort) x);
}

/// Store a shape id into a `ulong`.
pragma(inline, true) ulong b2StoreShapeId(b2ShapeId id) pure
{
    return (cast(ulong) id.index1 << 32) | (cast(ulong) id.world0) << 16 | cast(ulong) id.generation;
}

/// Load a `ulong` into a shape id.
pragma(inline, true) b2ShapeId b2LoadShapeId(ulong x) pure
{
    return b2ShapeId(cast(int)(x >> 32), cast(ushort)(x >> 16), cast(ushort) x);
}

/// Store a chain id into a `ulong`.
pragma(inline, true) ulong b2StoreChainId(b2ChainId id) pure
{
    return (cast(ulong) id.index1 << 32) | (cast(ulong) id.world0) << 16 | cast(ulong) id.generation;
}

/// Load a `ulong` into a chain id.
pragma(inline, true) b2ChainId b2LoadChainId(ulong x) pure
{
    return b2ChainId(cast(int)(x >> 32), cast(ushort)(x >> 16), cast(ushort) x);
}

/// Store a joint id into a `ulong`.
pragma(inline, true) ulong b2StoreJointId(b2JointId id) pure
{
    return (cast(ulong) id.index1 << 32) | (cast(ulong) id.world0) << 16 | cast(ulong) id.generation;
}

/// Load a `ulong` into a joint id.
pragma(inline, true) b2JointId b2LoadJointId(ulong x) pure
{
    return b2JointId(cast(int)(x >> 32), cast(ushort)(x >> 16), cast(ushort) x);
}

/// Store a contact id into three `uint` values.
pragma(inline, true) void b2StoreContactId(b2ContactId id, ref uint[3] values) pure
{
    values[0] = cast(uint) id.index1;
    values[1] = cast(uint) id.world0;
    values[2] = cast(uint) id.generation;
}

/// Load three `uint` values into a contact id.
pragma(inline, true) b2ContactId b2LoadContactId(ref const uint[3] values) pure
{
    b2ContactId id;
    id.index1 = cast(int) values[0];
    id.world0 = cast(ushort) values[1];
    id.padding = 0;
    id.generation = cast(uint) values[2];
    return id;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

@safe unittest
{
    // Body id survives a store/load round trip.
    b2BodyId id = b2BodyId(0x01234567, 0xABCD, 0x89EF);
    assert(b2LoadBodyId(b2StoreBodyId(id)) == id);
}

@safe unittest
{
    // World id survives a store/load round trip.
    b2WorldId id = b2WorldId(0x1234, 0x5678);
    assert(b2LoadWorldId(b2StoreWorldId(id)) == id);
}

@safe unittest
{
    // A zero-initialized id is null; a non-zero index is non-null.
    assert(B2_IS_NULL(b2BodyId.init));
    assert(B2_IS_NON_NULL(b2BodyId(1, 0, 0)));
}

@safe unittest
{
    // Contact ids round trip through three uint values.
    b2ContactId id = b2ContactId(0x11223344, 0x5566, 0, 0x99AABBCC);
    uint[3] values;
    b2StoreContactId(id, values);
    assert(b2LoadContactId(values) == id);
}
