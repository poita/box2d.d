// SPDX-License-Identifier: MIT
/++
    Base functionality: allocator/assert/log overrides, versioning and timing.

    Translated from `box2d/base.h`.
+/
module box2d.base;

@nogc nothrow:

extern (C):

/// Prototype for user allocation function.
/// Params:
///   size = the allocation size in bytes
///   alignment = the required alignment, guaranteed to be a power of 2
alias b2AllocFcn = void* function(size_t size, int alignment);

/// Prototype for user free function.
/// Params:
///   mem = the memory previously allocated through a `b2AllocFcn`
///   size = the allocation size in bytes
alias b2FreeFcn = void function(void* mem, size_t size);

/// Prototype for the user assert callback. Return 0 to skip the debugger break.
alias b2AssertFcn = int function(const(char)* condition, const(char)* fileName, int lineNumber);

/// Prototype for user log callback. Used to log warnings.
alias b2LogFcn = void function(const(char)* message);

/// Override the default allocation functions. Set these during application startup.
void b2SetAllocator(b2AllocFcn allocFcn, b2FreeFcn freeFcn);

/// Returns: the total bytes allocated by Box2D.
long b2GetByteCount();

/// Override the default assert function with a non-null assert callback.
void b2SetAssertFcn(b2AssertFcn assertFcn);

/// Override the default log function with a non-null log callback.
void b2SetLogFcn(b2LogFcn logFcn);

/// Version numbering scheme. See https://semver.org/
struct b2Version
{
    int major; /// Significant changes
    int minor; /// Incremental changes
    int revision; /// Bug fixes
}

/// Returns: the current version of Box2D.
b2Version b2GetVersion();

/// Returns: true if the library was built with BOX2D_DOUBLE_PRECISION (large world mode).
bool b2IsDoublePrecision();

/// Get the absolute number of system ticks. The value is platform specific.
ulong b2GetTicks();

/// Get the milliseconds passed from an initial tick value.
float b2GetMilliseconds(ulong ticks);

/// Get the milliseconds passed from an initial tick value.
/// Resets the passed in value to the current tick value.
float b2GetMillisecondsAndReset(ulong* ticks);

/// Yield to be used in a busy loop.
void b2Yield();

/// Simple djb2 hash function for determinism testing.
uint b2Hash(uint hash, const(ubyte)* data, int count);

extern (D):

/// Seed value for `b2Hash`.
enum uint B2_HASH_INIT = 5381;

/// Used to indicate an unset or invalid index value.
enum int B2_NULL_INDEX = -1;
