// SPDX-License-Identifier: MIT
/++
    Tuning constants.

    Translated from `box2d/constants.h`. Values that the C header derives from
    `b2_lengthUnitsPerMeter` are exposed here as functions, since they depend on
    runtime configuration; the remaining fixed values are manifest constants.
+/
module box2d.constants;

import box2d.math_functions : B2_PI, b2_lengthUnitsPerMeter;

@safe nothrow @nogc:

/// Maximum parallel workers. Used for some fixed size arrays.
enum int B2_MAX_WORKERS = 32;

/// Maximum number of tasks queued per world step.
enum int B2_MAX_TASKS = 256;

/// Maximum number of colors in the constraint graph.
enum int B2_GRAPH_COLOR_COUNT = 24;

/// Maximum number of simultaneous worlds that can be allocated.
enum int B2_MAX_WORLDS = 128;

/// Maximum length of a body name. Can be 0 if you don't need names.
enum int B2_NAME_LENGTH = 10;

/// The maximum rotation of a body per time step.
enum float B2_MAX_ROTATION = 0.25f * B2_PI;

/// The default contact recycling world angle threshold. 0.98 ~= 11.5 degrees.
enum float B2_CONTACT_RECYCLE_COS_ANGLE = 0.98f;

/// For small objects the AABB margin is limited to this fraction times the maximum extent.
enum float B2_AABB_MARGIN_FRACTION = 0.125f;

/// The time that a body must be still before it will go to sleep. In seconds.
enum float B2_TIME_TO_SLEEP = 0.5f;

/// The maximum number of restitution iterations. Needed to avoid a solver overflow.
enum int B2_MAX_RESTITUTION_ITERATIONS = 63;

// The length-scaled values below read the library's exported global.
@trusted:

/// Used to detect bad values. Depends on the configured length units.
pragma(inline, true) float B2_HUGE() => (100.0f * 1000.0f) * b2_lengthUnitsPerMeter;

/// A small length used as a collision and constraint tolerance, in meters.
pragma(inline, true) float B2_LINEAR_SLOP() => 0.005f * b2_lengthUnitsPerMeter;

/// Limited speculative collision distance. Reduces jitter.
pragma(inline, true) float B2_SPECULATIVE_DISTANCE() => 4.0f * B2_LINEAR_SLOP();

/// The default contact recycling distance.
pragma(inline, true) float B2_CONTACT_RECYCLE_DISTANCE() => 10.0f * B2_LINEAR_SLOP();

/// This is used to fatten AABBs in the dynamic tree, in meters.
pragma(inline, true) float B2_MAX_AABB_MARGIN() => 0.05f * b2_lengthUnitsPerMeter;
