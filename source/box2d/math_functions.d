// SPDX-License-Identifier: MIT
/++
    Vector math types and functions.

    Translated from `box2d/math_functions.h`. The header-only inline helpers are
    reimplemented in D; the remaining `B2_API` functions are `extern(C)` bindings
    into the library.

    This binds the default single-precision build of Box2D, so `b2Pos` aliases
    `b2Vec2` and `b2WorldTransform` aliases `b2Transform`.
+/
module box2d.math_functions;

import core.stdc.math : sqrtf, remainderf;

@safe nothrow @nogc:

/// https://en.wikipedia.org/wiki/Pi
enum float B2_PI = 3.14159265359f;

/// 2D vector. Can represent a point or a free vector.
struct b2Vec2
{
    float x = 0; /// coordinates
    float y = 0; /// ditto

    /// Vector negation.
    b2Vec2 opUnary(string op : "-")() const pure => b2Vec2(-x, -y);

    /// Vector addition and subtraction.
    b2Vec2 opBinary(string op)(b2Vec2 rhs) const pure if (op == "+" || op == "-")
    {
        return mixin("b2Vec2(x " ~ op ~ " rhs.x, y " ~ op ~ " rhs.y)");
    }

    /// Scalar multiplication (`v * s` and `s * v`).
    b2Vec2 opBinary(string op : "*")(float s) const pure => b2Vec2(x * s, y * s);
    b2Vec2 opBinaryRight(string op : "*")(float s) const pure => b2Vec2(s * x, s * y); /// ditto

    /// Compound assignment.
    ref b2Vec2 opOpAssign(string op)(b2Vec2 rhs) pure if (op == "+" || op == "-")
    {
        mixin("x " ~ op ~ "= rhs.x; y " ~ op ~ "= rhs.y;");
        return this;
    }

    /// ditto
    ref b2Vec2 opOpAssign(string op : "*")(float s) pure
    {
        x *= s;
        y *= s;
        return this;
    }
}

/// Cosine and sine pair. Uses a custom implementation for cross-platform determinism.
struct b2CosSin
{
    float cosine = 0; /// cosine
    float sine = 0; /// sine
}

/// 2D rotation, similar to a unit complex number.
struct b2Rot
{
    float c = 1; /// cosine
    float s = 0; /// sine
}

/// A 2D rigid transform.
struct b2Transform
{
    b2Vec2 p;
    b2Rot q;
}

/// A world position. Single precision in the default build.
alias b2Pos = b2Vec2;

/// A world transform. Single precision in the default build.
alias b2WorldTransform = b2Transform;

/// A 2-by-2 matrix, stored in column-major order.
struct b2Mat22
{
    b2Vec2 cx; /// columns
    b2Vec2 cy; /// ditto
}

/// Axis-aligned bounding box.
struct b2AABB
{
    b2Vec2 lowerBound;
    b2Vec2 upperBound;
}

/// A plane: `separation = dot(normal, point) - offset`.
struct b2Plane
{
    b2Vec2 normal;
    float offset = 0;
}

/// Zero vector.
enum b2Vec2 b2Vec2_zero = b2Vec2(0.0f, 0.0f);

/// Identity rotation.
enum b2Rot b2Rot_identity = b2Rot(1.0f, 0.0f);

/// Identity transform.
enum b2Transform b2Transform_identity = b2Transform(b2Vec2(0.0f, 0.0f), b2Rot(1.0f, 0.0f));

/// Zero matrix.
enum b2Mat22 b2Mat22_zero = b2Mat22(b2Vec2(0.0f, 0.0f), b2Vec2(0.0f, 0.0f));

/// Zero world position.
enum b2Pos b2Pos_zero = b2Pos(0.0f, 0.0f);

/// Identity world transform.
enum b2WorldTransform b2WorldTransform_identity = b2WorldTransform(b2Vec2(0.0f, 0.0f), b2Rot(1.0f, 0.0f));

extern (C):

/// Is this a valid number? Not NaN or infinity.
bool b2IsValidFloat(float a);

/// Is this a valid vector? Not NaN or infinity.
bool b2IsValidVec2(b2Vec2 v);

/// Is this a valid rotation? Not NaN or infinity. Is normalized.
bool b2IsValidRotation(b2Rot q);

/// Is this a valid transform? Not NaN or infinity. Rotation is normalized.
bool b2IsValidTransform(b2Transform t);

/// Is this a valid bounding box? Upper bound greater than or equal to lower bound.
bool b2IsValidAABB(b2AABB aabb);

/// Is this a valid plane? Normal is a unit vector. Not NaN or infinity.
bool b2IsValidPlane(b2Plane a);

/// Is this a valid world position? Not NaN or infinity.
bool b2IsValidPosition(b2Pos p);

/// Is this a valid world transform? Not NaN or infinity. Rotation is normalized.
bool b2IsValidWorldTransform(b2WorldTransform t);

/// Compute an approximate arctangent in the range [-pi, pi].
/// Hand coded for cross-platform determinism. Accurate to around 0.0023 degrees.
float b2Atan2(float y, float x);

/// Compute the cosine and sine of an angle in radians (cross-platform deterministic).
b2CosSin b2ComputeCosSin(float radians);

/// Compute the rotation between two unit vectors.
b2Rot b2ComputeRotationBetweenUnitVectors(b2Vec2 v1, b2Vec2 v2);

/// Set the length units per meter. Must be modified before any other calls to Box2D.
void b2SetLengthUnitsPerMeter(float lengthUnits);

/// Get the current length units per meter.
float b2GetLengthUnitsPerMeter();

extern (D):

@safe:

/// Returns: the minimum of two integers.
pragma(inline, true) int b2MinInt(int a, int b) => a < b ? a : b;

/// Returns: the maximum of two integers.
pragma(inline, true) int b2MaxInt(int a, int b) => a > b ? a : b;

/// Returns: the absolute value of an integer.
pragma(inline, true) int b2AbsInt(int a) => a < 0 ? -a : a;

/// Returns: an integer clamped between a lower and upper bound.
pragma(inline, true) int b2ClampInt(int a, int lower, int upper) => a < lower ? lower : (a > upper ? upper : a);

/// Ceiling of `numerator / denominator` for non-negative integers.
pragma(inline, true) int b2CeilingInt(int numerator, int denominator) => (numerator + denominator - 1) / denominator;

/// Returns: the minimum of two floats.
pragma(inline, true) float b2MinFloat(float a, float b) => a < b ? a : b;

/// Returns: the maximum of two floats.
pragma(inline, true) float b2MaxFloat(float a, float b) => a > b ? a : b;

/// Returns: the absolute value of a float.
pragma(inline, true) float b2AbsFloat(float a) => a < 0 ? -a : a;

/// Returns: a float clamped between a lower and upper bound.
pragma(inline, true) float b2ClampFloat(float a, float lower, float upper) => a < lower ? lower : (a > upper ? upper : a);

/// Vector dot product.
pragma(inline, true) float b2Dot(b2Vec2 a, b2Vec2 b) => a.x * b.x + a.y * b.y;

/// Vector cross product. In 2D this yields a scalar.
pragma(inline, true) float b2Cross(b2Vec2 a, b2Vec2 b) => a.x * b.y - a.y * b.x;

/// Cross product of a vector and a scalar. In 2D this produces a vector.
pragma(inline, true) b2Vec2 b2CrossVS(b2Vec2 v, float s) => b2Vec2(s * v.y, -s * v.x);

/// Cross product of a scalar and a vector. In 2D this produces a vector.
pragma(inline, true) b2Vec2 b2CrossSV(float s, b2Vec2 v) => b2Vec2(-s * v.y, s * v.x);

/// Left pointing perpendicular vector. Equivalent to `b2CrossSV(1, v)`.
pragma(inline, true) b2Vec2 b2LeftPerp(b2Vec2 v) => b2Vec2(-v.y, v.x);

/// Right pointing perpendicular vector. Equivalent to `b2CrossVS(v, 1)`.
pragma(inline, true) b2Vec2 b2RightPerp(b2Vec2 v) => b2Vec2(v.y, -v.x);

/// Vector addition.
pragma(inline, true) b2Vec2 b2Add(b2Vec2 a, b2Vec2 b) => b2Vec2(a.x + b.x, a.y + b.y);

/// Vector subtraction.
pragma(inline, true) b2Vec2 b2Sub(b2Vec2 a, b2Vec2 b) => b2Vec2(a.x - b.x, a.y - b.y);

/// Vector negation.
pragma(inline, true) b2Vec2 b2Neg(b2Vec2 a) => b2Vec2(-a.x, -a.y);

/// Vector linear interpolation.
pragma(inline, true) b2Vec2 b2Lerp(b2Vec2 a, b2Vec2 b, float t)
    => b2Vec2((1.0f - t) * a.x + t * b.x, (1.0f - t) * a.y + t * b.y);

/// Component-wise multiplication.
pragma(inline, true) b2Vec2 b2Mul(b2Vec2 a, b2Vec2 b) => b2Vec2(a.x * b.x, a.y * b.y);

/// Multiply a scalar and a vector.
pragma(inline, true) b2Vec2 b2MulSV(float s, b2Vec2 v) => b2Vec2(s * v.x, s * v.y);

/// `a + s * b`.
pragma(inline, true) b2Vec2 b2MulAdd(b2Vec2 a, float s, b2Vec2 b) => b2Vec2(a.x + s * b.x, a.y + s * b.y);

/// `a - s * b`.
pragma(inline, true) b2Vec2 b2MulSub(b2Vec2 a, float s, b2Vec2 b) => b2Vec2(a.x - s * b.x, a.y - s * b.y);

/// Component-wise absolute value.
pragma(inline, true) b2Vec2 b2Abs(b2Vec2 a) => b2Vec2(b2AbsFloat(a.x), b2AbsFloat(a.y));

/// Component-wise minimum.
pragma(inline, true) b2Vec2 b2Min(b2Vec2 a, b2Vec2 b) => b2Vec2(b2MinFloat(a.x, b.x), b2MinFloat(a.y, b.y));

/// Component-wise maximum.
pragma(inline, true) b2Vec2 b2Max(b2Vec2 a, b2Vec2 b) => b2Vec2(b2MaxFloat(a.x, b.x), b2MaxFloat(a.y, b.y));

/// Component-wise clamp of `v` into the range `[a, b]`.
pragma(inline, true) b2Vec2 b2Clamp(b2Vec2 v, b2Vec2 a, b2Vec2 b)
    => b2Vec2(b2ClampFloat(v.x, a.x, b.x), b2ClampFloat(v.y, a.y, b.y));

/// Get the length (norm) of a vector.
pragma(inline, true) float b2Length(b2Vec2 v) => sqrtf(v.x * v.x + v.y * v.y);

/// Get the distance between two points.
pragma(inline, true) float b2Distance(b2Vec2 a, b2Vec2 b)
{
    immutable float dx = b.x - a.x;
    immutable float dy = b.y - a.y;
    return sqrtf(dx * dx + dy * dy);
}

/// Convert a vector into a unit vector if possible, otherwise the zero vector.
b2Vec2 b2Normalize(b2Vec2 v)
{
    immutable float length = sqrtf(v.x * v.x + v.y * v.y);
    if (length < float.epsilon)
        return b2Vec2(0.0f, 0.0f);

    immutable float invLength = 1.0f / length;
    return b2Vec2(invLength * v.x, invLength * v.y);
}

/// Determines if the provided vector is normalized (norm == 1).
pragma(inline, true) bool b2IsNormalized(b2Vec2 a)
{
    immutable float aa = b2Dot(a, a);
    return b2AbsFloat(1.0f - aa) < 100.0f * float.epsilon;
}

/// Convert a vector into a unit vector, also outputting the original length.
b2Vec2 b2GetLengthAndNormalize(scope float* length, b2Vec2 v) @system
{
    *length = sqrtf(v.x * v.x + v.y * v.y);
    if (*length < float.epsilon)
        return b2Vec2(0.0f, 0.0f);

    immutable float invLength = 1.0f / *length;
    return b2Vec2(invLength * v.x, invLength * v.y);
}

/// Normalize a rotation.
b2Rot b2NormalizeRot(b2Rot q)
{
    immutable float mag = sqrtf(q.s * q.s + q.c * q.c);
    immutable float invMag = mag > 0.0f ? 1.0f / mag : 0.0f;
    return b2Rot(q.c * invMag, q.s * invMag);
}

/// Integrate rotation from angular velocity.
/// Params:
///   q1 = initial rotation
///   deltaAngle = the angular displacement in radians
b2Rot b2IntegrateRotation(b2Rot q1, float deltaAngle)
{
    immutable b2Rot q2 = b2Rot(q1.c - deltaAngle * q1.s, q1.s + deltaAngle * q1.c);
    immutable float mag = sqrtf(q2.s * q2.s + q2.c * q2.c);
    immutable float invMag = mag > 0.0f ? 1.0f / mag : 0.0f;
    return b2Rot(q2.c * invMag, q2.s * invMag);
}

/// Get the squared length of a vector.
pragma(inline, true) float b2LengthSquared(b2Vec2 v) => v.x * v.x + v.y * v.y;

/// Get the squared distance between two points.
pragma(inline, true) float b2DistanceSquared(b2Vec2 a, b2Vec2 b)
{
    immutable b2Vec2 c = b2Vec2(b.x - a.x, b.y - a.y);
    return c.x * c.x + c.y * c.y;
}

/// Make a rotation using an angle in radians.
pragma(inline, true) b2Rot b2MakeRot(float radians)
{
    immutable b2CosSin cs = b2ComputeCosSin(radians);
    return b2Rot(cs.cosine, cs.sine);
}

/// Make a rotation using a unit vector.
pragma(inline, true) b2Rot b2MakeRotFromUnitVector(b2Vec2 unitVector) => b2Rot(unitVector.x, unitVector.y);

/// Is this rotation normalized?
pragma(inline, true) bool b2IsNormalizedRot(b2Rot q)
{
    immutable float qq = q.s * q.s + q.c * q.c;
    return 1.0f - 0.0006f < qq && qq < 1.0f + 0.0006f;
}

/// Get the inverse of a rotation.
pragma(inline, true) b2Rot b2InvertRot(b2Rot a) => b2Rot(a.c, -a.s);

/// Normalized linear interpolation of two rotations.
b2Rot b2NLerp(b2Rot q1, b2Rot q2, float t)
{
    immutable float omt = 1.0f - t;
    immutable b2Rot q = b2Rot(omt * q1.c + t * q2.c, omt * q1.s + t * q2.s);
    immutable float mag = sqrtf(q.s * q.s + q.c * q.c);
    immutable float invMag = mag > 0.0f ? 1.0f / mag : 0.0f;
    return b2Rot(q.c * invMag, q.s * invMag);
}

/// Compute the angular velocity needed to rotate between two rotations over a time step.
/// Params:
///   q1 = initial rotation
///   q2 = final rotation
///   inv_h = inverse time step
pragma(inline, true) float b2ComputeAngularVelocity(b2Rot q1, b2Rot q2, float inv_h)
    => inv_h * (q2.s * q1.c - q2.c * q1.s);

/// Get the angle of a rotation in radians in the range [-pi, pi].
pragma(inline, true) float b2Rot_GetAngle(b2Rot q) => b2Atan2(q.s, q.c);

/// Get the x-axis of a rotation.
pragma(inline, true) b2Vec2 b2Rot_GetXAxis(b2Rot q) => b2Vec2(q.c, q.s);

/// Get the y-axis of a rotation.
pragma(inline, true) b2Vec2 b2Rot_GetYAxis(b2Rot q) => b2Vec2(-q.s, q.c);

/// Multiply two rotations: `q * r`.
pragma(inline, true) b2Rot b2MulRot(b2Rot q, b2Rot r)
    => b2Rot(q.c * r.c - q.s * r.s, q.s * r.c + q.c * r.s);

/// Transpose multiply two rotations: `inv(a) * b`.
/// Rotates a vector local in frame b into a vector local in frame a.
pragma(inline, true) b2Rot b2InvMulRot(b2Rot a, b2Rot b)
    => b2Rot(a.c * b.c + a.s * b.s, a.c * b.s - a.s * b.c);

/// Relative angle between `a` and `b` (i.e. angle of `inv(a) * b`).
pragma(inline, true) float b2RelativeAngle(b2Rot a, b2Rot b)
{
    immutable float s = a.c * b.s - a.s * b.c;
    immutable float c = a.c * b.c + a.s * b.s;
    return b2Atan2(s, c);
}

/// Convert any angle into the range [-pi, pi].
pragma(inline, true) float b2UnwindAngle(float radians) => remainderf(radians, 2.0f * B2_PI);

/// Rotate a vector.
pragma(inline, true) b2Vec2 b2RotateVector(b2Rot q, b2Vec2 v)
    => b2Vec2(q.c * v.x - q.s * v.y, q.s * v.x + q.c * v.y);

/// Inverse rotate a vector.
pragma(inline, true) b2Vec2 b2InvRotateVector(b2Rot q, b2Vec2 v)
    => b2Vec2(q.c * v.x + q.s * v.y, -q.s * v.x + q.c * v.y);

/// Transform a point (e.g. local space to world space).
pragma(inline, true) b2Vec2 b2TransformPoint(b2Transform t, const b2Vec2 p)
    => b2Vec2((t.q.c * p.x - t.q.s * p.y) + t.p.x, (t.q.s * p.x + t.q.c * p.y) + t.p.y);

/// Inverse transform a point (e.g. world space to local space).
pragma(inline, true) b2Vec2 b2InvTransformPoint(b2Transform t, const b2Vec2 p)
{
    immutable float vx = p.x - t.p.x;
    immutable float vy = p.y - t.p.y;
    return b2Vec2(t.q.c * vx + t.q.s * vy, -t.q.s * vx + t.q.c * vy);
}

/// Multiply two transforms.
pragma(inline, true) b2Transform b2MulTransforms(b2Transform A, b2Transform B)
    => b2Transform(b2Add(b2RotateVector(A.q, B.p), A.p), b2MulRot(A.q, B.q));

/// Creates a transform that converts a local point in frame B to a local point in frame A.
pragma(inline, true) b2Transform b2InvMulTransforms(b2Transform A, b2Transform B)
    => b2Transform(b2InvRotateVector(A.q, b2Sub(B.p, A.p)), b2InvMulRot(A.q, B.q));

/// Convert a vector to a world position. No-op in single precision.
pragma(inline, true) b2Pos b2ToPos(b2Vec2 v) => b2Pos(v.x, v.y);

/// Lossy conversion of a world position to a float vector. No-op in single precision.
pragma(inline, true) b2Vec2 b2ToVec2(b2Pos p) => b2Vec2(p.x, p.y);

/// Narrow a world coordinate to float, rounding toward negative infinity.
/// Plain conversion in single precision.
pragma(inline, true) float b2RoundDownFloat(double x) => cast(float) x;

/// Narrow a world coordinate to float, rounding toward positive infinity.
/// Plain conversion in single precision.
pragma(inline, true) float b2RoundUpFloat(double x) => cast(float) x;

/// `a - b`, demoted to float. The primary precision boundary operation.
pragma(inline, true) b2Vec2 b2SubPos(b2Pos a, b2Pos b) => b2Vec2(a.x - b.x, a.y - b.y);

/// `p + d`.
pragma(inline, true) b2Pos b2OffsetPos(b2Pos p, b2Vec2 d) => b2Pos(p.x + d.x, p.y + d.y);

/// World position interpolation for sweeps and sampling.
pragma(inline, true) b2Pos b2LerpPosition(b2Pos a, b2Pos b, float t)
    => b2Pos((1.0f - t) * a.x + t * b.x, (1.0f - t) * a.y + t * b.y);

/// Transform a local point to a world position.
pragma(inline, true) b2Pos b2TransformWorldPoint(b2WorldTransform t, b2Vec2 p)
{
    immutable float rx = t.q.c * p.x - t.q.s * p.y;
    immutable float ry = t.q.s * p.x + t.q.c * p.y;
    return b2Pos(t.p.x + rx, t.p.y + ry);
}

/// Transform a world position to a local point.
pragma(inline, true) b2Vec2 b2InvTransformWorldPoint(b2WorldTransform t, b2Pos p)
{
    immutable float vx = cast(float)(p.x - t.p.x);
    immutable float vy = cast(float)(p.y - t.p.y);
    return b2Vec2(t.q.c * vx + t.q.s * vy, -t.q.s * vx + t.q.c * vy);
}

/// Relative transform of frame B in frame A.
pragma(inline, true) b2Transform b2InvMulWorldTransforms(b2WorldTransform A, b2WorldTransform B)
{
    immutable b2Vec2 d = b2Vec2(cast(float)(B.p.x - A.p.x), cast(float)(B.p.y - A.p.y));
    return b2Transform(b2InvRotateVector(A.q, d), b2InvMulRot(A.q, B.q));
}

/// Convert a local transform B into world space using world transform A.
pragma(inline, true) b2WorldTransform b2OffsetWorldTransform(b2WorldTransform A, b2Transform B)
    => b2WorldTransform(b2OffsetPos(A.p, b2RotateVector(A.q, B.p)), b2MulRot(A.q, B.q));

/// Shift a world transform into the frame of a base position.
pragma(inline, true) b2Transform b2ToRelativeTransform(b2WorldTransform t, b2Pos base)
    => b2Transform(b2Vec2(cast(float)(t.p.x - base.x), cast(float)(t.p.y - base.y)), t.q);

/// Promote a float transform to a world transform. Lossless.
pragma(inline, true) b2WorldTransform b2MakeWorldTransform(b2Transform t)
    => b2WorldTransform(b2ToPos(t.p), t.q);

/// Multiply a 2-by-2 matrix by a 2D vector.
pragma(inline, true) b2Vec2 b2MulMV(b2Mat22 A, b2Vec2 v)
    => b2Vec2(A.cx.x * v.x + A.cy.x * v.y, A.cx.y * v.x + A.cy.y * v.y);

/// Get the inverse of a 2-by-2 matrix.
b2Mat22 b2GetInverse22(b2Mat22 A)
{
    immutable float a = A.cx.x, b = A.cy.x, c = A.cx.y, d = A.cy.y;
    float det = a * d - b * c;
    if (det != 0.0f)
        det = 1.0f / det;
    return b2Mat22(b2Vec2(det * d, -det * c), b2Vec2(-det * b, det * a));
}

/// Solve `A * x = b`, where `b` is a column vector.
b2Vec2 b2Solve22(b2Mat22 A, b2Vec2 b)
{
    immutable float a11 = A.cx.x, a12 = A.cy.x, a21 = A.cx.y, a22 = A.cy.y;
    float det = a11 * a22 - a12 * a21;
    if (det != 0.0f)
        det = 1.0f / det;
    return b2Vec2(det * (a22 * b.x - a12 * b.y), det * (a11 * b.y - a21 * b.x));
}

/// Does `a` fully contain `b`?
pragma(inline, true) bool b2AABB_Contains(b2AABB a, b2AABB b)
{
    return a.lowerBound.x <= b.lowerBound.x && a.lowerBound.y <= b.lowerBound.y
        && b.upperBound.x <= a.upperBound.x && b.upperBound.y <= a.upperBound.y;
}

/// Get the center of an AABB.
pragma(inline, true) b2Vec2 b2AABB_Center(b2AABB a)
    => b2Vec2(0.5f * (a.lowerBound.x + a.upperBound.x), 0.5f * (a.lowerBound.y + a.upperBound.y));

/// Get the extents (half-widths) of an AABB.
pragma(inline, true) b2Vec2 b2AABB_Extents(b2AABB a)
    => b2Vec2(0.5f * (a.upperBound.x - a.lowerBound.x), 0.5f * (a.upperBound.y - a.lowerBound.y));

/// Union of two AABBs.
pragma(inline, true) b2AABB b2AABB_Union(b2AABB a, b2AABB b)
{
    return b2AABB(
        b2Vec2(b2MinFloat(a.lowerBound.x, b.lowerBound.x), b2MinFloat(a.lowerBound.y, b.lowerBound.y)),
        b2Vec2(b2MaxFloat(a.upperBound.x, b.upperBound.x), b2MaxFloat(a.upperBound.y, b.upperBound.y)));
}

/// Do `a` and `b` overlap?
pragma(inline, true) bool b2AABB_Overlaps(b2AABB a, b2AABB b)
{
    return !(b.lowerBound.x > a.upperBound.x || b.lowerBound.y > a.upperBound.y
            || a.lowerBound.x > b.upperBound.x || a.lowerBound.y > b.upperBound.y);
}

/// Compute the bounding box of an array of circles.
b2AABB b2MakeAABB(scope const b2Vec2* points, int count, float radius) @system
{
    b2AABB a = b2AABB(points[0], points[0]);
    foreach (i; 1 .. count)
    {
        a.lowerBound = b2Min(a.lowerBound, points[i]);
        a.upperBound = b2Max(a.upperBound, points[i]);
    }

    immutable b2Vec2 r = b2Vec2(radius, radius);
    a.lowerBound = b2Sub(a.lowerBound, r);
    a.upperBound = b2Add(a.upperBound, r);
    return a;
}

/// Signed separation of a point from a plane.
pragma(inline, true) float b2PlaneSeparation(b2Plane plane, b2Vec2 point)
    => b2Dot(plane.normal, point) - plane.offset;

/// One-dimensional mass-spring-damper simulation. Returns the new velocity.
pragma(inline, true) float b2SpringDamper(float hertz, float dampingRatio, float position, float velocity, float timeStep)
{
    immutable float omega = 2.0f * B2_PI * hertz;
    immutable float omegaH = omega * timeStep;
    return (velocity - omega * omegaH * position) / (1.0f + 2.0f * dampingRatio * omegaH + omegaH * omegaH);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

@safe unittest
{
    // Free-function vector arithmetic.
    immutable a = b2Vec2(1.0f, 2.0f);
    immutable b = b2Vec2(3.0f, 4.0f);
    assert(b2Add(a, b) == b2Vec2(4.0f, 6.0f));
    assert(b2Sub(b, a) == b2Vec2(2.0f, 2.0f));
    assert(b2Dot(a, b) == 11.0f);
    assert(b2Cross(a, b) == -2.0f);
    assert(b2MulSV(2.0f, a) == b2Vec2(2.0f, 4.0f));
}

@safe unittest
{
    // Operator overloads mirror the free functions.
    immutable a = b2Vec2(1.0f, 2.0f);
    immutable b = b2Vec2(3.0f, 4.0f);
    assert(a + b == b2Vec2(4.0f, 6.0f));
    assert(b - a == b2Vec2(2.0f, 2.0f));
    assert(2.0f * a == b2Vec2(2.0f, 4.0f));
    assert(a * 2.0f == b2Vec2(2.0f, 4.0f));
    assert(-a == b2Vec2(-1.0f, -2.0f));

    b2Vec2 c = a;
    c += b;
    c -= a;
    c *= 2.0f;
    assert(c == b2Vec2(6.0f, 8.0f));
}

@safe unittest
{
    // Length and normalization.
    immutable v = b2Vec2(3.0f, 4.0f);
    assert(b2LengthSquared(v) == 25.0f);
    assert(b2Length(v) == 5.0f);
    immutable n = b2Normalize(v);
    assert(b2AbsFloat(b2Length(n) - 1.0f) < 1.0e-5f);
    assert(b2Normalize(b2Vec2(0.0f, 0.0f)) == b2Vec2(0.0f, 0.0f));
}

@safe unittest
{
    // Identity rotation leaves vectors and rotations unchanged.
    immutable v = b2Vec2(2.0f, -3.0f);
    assert(b2RotateVector(b2Rot_identity, v) == v);
    immutable r = b2MulRot(b2Rot_identity, b2Rot_identity);
    assert(r.c == 1.0f && r.s == 0.0f);
    assert(b2InvertRot(b2Rot_identity).c == 1.0f);
}

@safe unittest
{
    // AABB containment, union and overlap.
    immutable outer = b2AABB(b2Vec2(0, 0), b2Vec2(10, 10));
    immutable inner = b2AABB(b2Vec2(2, 2), b2Vec2(5, 5));
    assert(b2AABB_Contains(outer, inner));
    assert(!b2AABB_Contains(inner, outer));
    assert(b2AABB_Overlaps(outer, inner));
    assert(b2AABB_Center(outer) == b2Vec2(5, 5));

    immutable u = b2AABB_Union(b2AABB(b2Vec2(0, 0), b2Vec2(1, 1)),
        b2AABB(b2Vec2(2, 2), b2Vec2(3, 3)));
    assert(u.lowerBound == b2Vec2(0, 0) && u.upperBound == b2Vec2(3, 3));
}

@safe unittest
{
    // Integer helpers.
    assert(b2MinInt(3, 7) == 3);
    assert(b2MaxInt(3, 7) == 7);
    assert(b2ClampInt(9, 0, 5) == 5);
    assert(b2AbsInt(-4) == 4);
    assert(b2CeilingInt(10, 4) == 3);
}
