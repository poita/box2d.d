// SPDX-License-Identifier: MIT
/++
    Geometry, distance, manifold, time-of-impact and dynamic-tree types and
    functions.

    Translated from `box2d/collision.h`.
+/
module box2d.collision;

import box2d.math_functions;

/// The maximum number of vertices on a convex polygon.
enum int B2_MAX_POLYGON_VERTICES = 8;

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------

/// Low level ray cast input data.
struct b2RayCastInput
{
    b2Vec2 origin; /// Start point of the ray cast
    b2Vec2 translation; /// Translation of the ray cast
    float maxFraction = 0; /// The maximum fraction of the translation to consider, typically 1
}

/// A distance proxy used by the GJK algorithm. Encapsulates any shape.
struct b2ShapeProxy
{
    b2Vec2[B2_MAX_POLYGON_VERTICES] points; /// The point cloud
    int count; /// The number of points. Must be greater than 0.
    float radius = 0; /// The external radius of the point cloud. May be zero.
}

/// Low level shape cast input in generic form.
struct b2ShapeCastInput
{
    b2ShapeProxy proxy; /// A generic shape
    b2Vec2 translation; /// The translation of the shape cast
    float maxFraction = 0; /// The maximum fraction of the translation to consider, typically 1
    bool canEncroach; /// Allow shape cast to encroach when initially touching (requires radius > 0).
}

/// Low level ray cast or shape-cast output data. The hit point is in the local or relative frame.
struct b2CastOutput
{
    b2Vec2 normal; /// The surface normal at the hit point
    b2Vec2 point; /// The surface hit point
    float fraction = 0; /// The fraction of the input translation at collision
    int iterations; /// The number of iterations used
    bool hit; /// Did the cast hit?
}

/// World-space cast output. Aliases `b2CastOutput` in the default single-precision build.
alias b2WorldCastOutput = b2CastOutput;

/// This holds the mass data computed for a shape.
struct b2MassData
{
    float mass = 0; /// The mass of the shape, usually in kilograms.
    b2Vec2 center; /// The position of the shape's centroid relative to the shape's origin.
    float rotationalInertia = 0; /// The rotational inertia of the shape about the shape center.
}

/// A solid circle.
struct b2Circle
{
    b2Vec2 center; /// The local center
    float radius = 0; /// The radius
}

/// A solid capsule: two semicircles connected by a rectangle.
struct b2Capsule
{
    b2Vec2 center1; /// Local center of the first semicircle
    b2Vec2 center2; /// Local center of the second semicircle
    float radius = 0; /// The radius of the semicircles
}

/// A solid convex polygon. Interior is to the left of each edge.
/// Do not fill this out manually; use a helper like `b2MakePolygon` or `b2MakeBox`.
struct b2Polygon
{
    b2Vec2[B2_MAX_POLYGON_VERTICES] vertices; /// The polygon vertices
    b2Vec2[B2_MAX_POLYGON_VERTICES] normals; /// The outward normal vectors of the polygon sides
    b2Vec2 centroid; /// The centroid of the polygon
    float radius = 0; /// The external radius for rounded polygons
    int count; /// The number of polygon vertices
}

/// A line segment with two-sided collision.
struct b2Segment
{
    b2Vec2 point1; /// The first point
    b2Vec2 point2; /// The second point
}

/// A line segment with one-sided collision (right side only), generated for chain shapes.
struct b2ChainSegment
{
    b2Vec2 ghost1; /// The tail ghost vertex
    b2Segment segment; /// The line segment
    b2Vec2 ghost2; /// The head ghost vertex
    int chainId; /// The owning chain shape index (internal usage only)
}

/// A convex hull. Used to create convex polygons.
/// Do not modify these values directly; use `b2ComputeHull`.
struct b2Hull
{
    b2Vec2[B2_MAX_POLYGON_VERTICES] points; /// The final points of the hull
    int count; /// The number of points
}

// ---------------------------------------------------------------------------
// Distance
// ---------------------------------------------------------------------------

/// Result of computing the distance between two line segments.
struct b2SegmentDistanceResult
{
    b2Vec2 closest1; /// The closest point on the first segment
    b2Vec2 closest2; /// The closest point on the second segment
    float fraction1 = 0; /// The barycentric coordinate on the first segment
    float fraction2 = 0; /// The barycentric coordinate on the second segment
    float distanceSquared = 0; /// The squared distance between the closest points
}

/// Used to warm start the GJK simplex. Zero initialize on the first call.
struct b2SimplexCache
{
    ushort count; /// The number of stored simplex points
    ubyte[3] indexA; /// The cached simplex indices on shape A
    ubyte[3] indexB; /// The cached simplex indices on shape B
}

/// An empty (zero-initialized) simplex cache.
enum b2SimplexCache b2_emptySimplexCache = b2SimplexCache.init;

/// Input for `b2ShapeDistance`.
struct b2DistanceInput
{
    b2ShapeProxy proxyA; /// The proxy for shape A
    b2ShapeProxy proxyB; /// The proxy for shape B
    b2Transform transform; /// Transform of shape B in shape A's frame
    bool useRadii; /// Should the proxy radius be considered?
}

/// Output for `b2ShapeDistance`.
struct b2DistanceOutput
{
    b2Vec2 pointA; /// Closest point on shapeA, in shape A's frame
    b2Vec2 pointB; /// Closest point on shapeB, in shape A's frame
    b2Vec2 normal; /// A to B normal in shape A's frame. Invalid if distance is zero.
    float distance = 0; /// The final distance, zero if overlapped
    int iterations; /// Number of GJK iterations used
    int simplexCount; /// The number of simplexes stored in the simplex array
}

/// Simplex vertex for debugging the GJK algorithm.
struct b2SimplexVertex
{
    b2Vec2 wA; /// support point in proxyA
    b2Vec2 wB; /// support point in proxyB
    b2Vec2 w; /// wB - wA
    float a = 0; /// barycentric coordinate for closest point
    int indexA; /// wA index
    int indexB; /// wB index
}

/// Simplex from the GJK algorithm.
struct b2Simplex
{
    b2SimplexVertex v1, v2, v3; /// vertices
    int count; /// number of valid vertices
}

/// Input parameters for `b2ShapeCast`.
struct b2ShapeCastPairInput
{
    b2ShapeProxy proxyA; /// The proxy for shape A
    b2ShapeProxy proxyB; /// The proxy for shape B
    b2Transform transform; /// Transform of shape B in shape A's frame
    b2Vec2 translationB; /// The translation of shape B, in A's frame
    float maxFraction = 0; /// The fraction of the translation to consider, typically 1
    bool canEncroach; /// Allows shapes with a radius to move slightly closer if already touching
}

/// Describes the motion of a body/shape for TOI computation.
struct b2Sweep
{
    b2Vec2 localCenter; /// Local center of mass position
    b2Vec2 c1; /// Starting center of mass world position
    b2Vec2 c2; /// Ending center of mass world position
    b2Rot q1; /// Starting world rotation
    b2Rot q2; /// Ending world rotation
}

/// Time of impact input.
struct b2TOIInput
{
    b2ShapeProxy proxyA; /// The proxy for shape A
    b2ShapeProxy proxyB; /// The proxy for shape B
    b2Sweep sweepA; /// The movement of shape A
    b2Sweep sweepB; /// The movement of shape B
    float maxFraction = 0; /// Defines the sweep interval [0, maxFraction]
}

/// Describes the TOI output.
enum b2TOIState
{
    b2_toiStateUnknown,
    b2_toiStateFailed,
    b2_toiStateOverlapped,
    b2_toiStateHit,
    b2_toiStateSeparated,
}

/// Time of impact output.
struct b2TOIOutput
{
    b2TOIState state; /// The type of result
    b2Vec2 point; /// The hit point
    b2Vec2 normal; /// The hit normal
    float fraction = 0; /// The sweep time of the collision
}

// ---------------------------------------------------------------------------
// Collision manifolds
// ---------------------------------------------------------------------------

/// A contact point belonging to a contact manifold.
struct b2ManifoldPoint
{
    b2Vec2 anchorA; /// Contact point relative to bodyA's center of mass in world space.
    b2Vec2 anchorB; /// Contact point relative to bodyB's center of mass in world space.
    float separation = 0; /// The separation of the contact point, negative if penetrating
    float baseSeparation = 0; /// Cached separation used for contact recycling
    float normalImpulse = 0; /// The impulse along the manifold normal vector.
    float tangentImpulse = 0; /// The friction impulse
    float totalNormalImpulse = 0; /// The total normal impulse across sub-stepping and restitution.
    float normalVelocity = 0; /// Relative normal velocity pre-solve. Used for hit events.
    ushort id; /// Uniquely identifies a contact point between two shapes
    bool persisted; /// Did this contact point exist the previous step?
}

/// A contact manifold describes the contact points between colliding shapes.
struct b2Manifold
{
    b2Vec2 normal; /// The unit normal vector in world space, points from shape A to bodyB
    float rollingImpulse = 0; /// Angular impulse applied for rolling resistance.
    b2ManifoldPoint[2] points; /// The manifold points, up to two are possible in 2D
    int pointCount; /// The number of contacts points: 0, 1, or 2
}

/// Contact manifold point in local coordinates (frame A).
struct b2LocalManifoldPoint
{
    b2Vec2 point; /// Contact point in frame A
    float separation = 0; /// The separation of the contact point, negative if penetrating.
    ushort id; /// Uniquely identifies a contact point between two shapes
}

/// Contact manifold in local coordinates (frame A).
struct b2LocalManifold
{
    b2Vec2 normal; /// The unit normal vector in frame A, points from shape A to shape B
    b2LocalManifoldPoint[2] points; /// The manifold points, up to two are possible in 2D
    int pointCount; /// The number of contacts points: 0, 1, or 2
}

// ---------------------------------------------------------------------------
// Dynamic tree
// ---------------------------------------------------------------------------

/// Tree node flags. For internal usage.
enum b2TreeNodeFlags
{
    b2_allocatedNode = 0x0001,
    b2_enlargedNode = 0x0002,
    b2_leafNode = 0x0004,
}

/// Tree node child indices. Internal usage.
struct b2TreeNodeChildren
{
    int child1; /// child node index 1
    int child2; /// child node index 2
}

/// A node in the dynamic tree. For internal usage.
struct b2TreeNode
{
    b2AABB aabb; /// The node bounding box
    ulong categoryBits; /// Category bits for collision filtering
    union
    {
        b2TreeNodeChildren children; /// Children (internal node)
        ulong userData; /// User data (leaf node)
    }

    union
    {
        int parent; /// The node parent index (allocated node)
        int next; /// The node freelist next index (free node)
    }

    ushort height;
    ushort flags;
}

/// The dynamic tree structure. This should be considered private data.
struct b2DynamicTree
{
    b2TreeNode* nodes; /// The tree nodes
    int root; /// The root index
    int nodeCount; /// The number of nodes
    int nodeCapacity; /// The allocated node space
    int freeList; /// Node free list
    int proxyCount; /// Number of proxies created
    int* leafIndices; /// Leaf indices for rebuild
    b2AABB* leafBoxes; /// Leaf bounding boxes for rebuild
    b2Vec2* leafCenters; /// Leaf bounding box centers for rebuild
    int* binIndices; /// Bins for sorting during rebuild
    int rebuildCapacity; /// Allocated space for rebuilding
}

/// Performance results returned by dynamic tree queries.
struct b2TreeStats
{
    int nodeVisits; /// Number of internal nodes visited during the query
    int leafVisits; /// Number of leaf nodes visited during the query
}

/// Input for casting an AABB through a dynamic tree.
struct b2BoxCastInput
{
    b2AABB box; /// The AABB to cast, in the tree's frame.
    b2Vec2 translation; /// The sweep translation.
    float maxFraction = 0; /// The maximum fraction of the translation to consider, typically 1.
}

// ---------------------------------------------------------------------------
// Character mover
// ---------------------------------------------------------------------------

/// A collision plane returned from `b2World_CollideMover`.
struct b2PlaneResult
{
    b2Plane plane; /// The collision plane between the mover and a convex shape
    b2Vec2 point; /// The collision point on the shape.
    bool hit; /// Did the collision register a hit? If not this plane should be ignored.
}

/// A collision plane that can be fed to `b2SolvePlanes`.
struct b2CollisionPlane
{
    b2Plane plane; /// The collision plane between the mover and some shape
    float pushLimit = 0; /// FLT_MAX makes the plane as rigid as possible; lower values soften it.
    float push = 0; /// The push on the mover determined by `b2SolvePlanes`.
    bool clipVelocity; /// Should `b2ClipVector` clip against this plane? False for soft collision.
}

/// Result returned by `b2SolvePlanes`.
struct b2PlaneSolverResult
{
    b2Vec2 translation; /// The translation of the mover
    int iterationCount; /// The number of iterations used by the plane solver.
}

// ---------------------------------------------------------------------------
// Callbacks
// ---------------------------------------------------------------------------

extern (C) nothrow:

/// Receives proxies found in an AABB query. Return true to continue.
alias b2TreeQueryCallbackFcn = bool function(int proxyId, ulong userData, void* context);

/// Receives clipped ray cast input for a proxy. Returns the new ray fraction.
alias b2TreeRayCastCallbackFcn = float function(const(b2RayCastInput)* input, int proxyId, ulong userData, void* context);

/// Receives clipped AABB cast input for a proxy. Returns the new cast fraction.
alias b2TreeBoxCastCallbackFcn = float function(const(b2BoxCastInput)* input, int proxyId, ulong userData, void* context);

// ---------------------------------------------------------------------------
// Functions
// ---------------------------------------------------------------------------

@nogc:

/// Validate ray cast input data (NaN, etc).
bool b2IsValidRay(const(b2RayCastInput)* input);

/// Make a convex polygon from a convex hull. Asserts if the hull is not valid.
b2Polygon b2MakePolygon(const(b2Hull)* hull, float radius);

/// Make an offset convex polygon from a convex hull.
b2Polygon b2MakeOffsetPolygon(const(b2Hull)* hull, b2Vec2 position, b2Rot rotation);

/// Make an offset rounded convex polygon from a convex hull.
b2Polygon b2MakeOffsetRoundedPolygon(const(b2Hull)* hull, b2Vec2 position, b2Rot rotation, float radius);

/// Make a square polygon, bypassing the need for a convex hull.
b2Polygon b2MakeSquare(float halfWidth);

/// Make a box (rectangle) polygon, bypassing the need for a convex hull.
b2Polygon b2MakeBox(float halfWidth, float halfHeight);

/// Make a rounded box, bypassing the need for a convex hull.
b2Polygon b2MakeRoundedBox(float halfWidth, float halfHeight, float radius);

/// Make an offset box, bypassing the need for a convex hull.
b2Polygon b2MakeOffsetBox(float halfWidth, float halfHeight, b2Vec2 center, b2Rot rotation);

/// Make an offset rounded box, bypassing the need for a convex hull.
b2Polygon b2MakeOffsetRoundedBox(float halfWidth, float halfHeight, b2Vec2 center, b2Rot rotation, float radius);

/// Transform a polygon. Useful for transferring a shape from one body to another.
b2Polygon b2TransformPolygon(b2Transform transform, const(b2Polygon)* polygon);

/// Compute mass properties of a circle.
b2MassData b2ComputeCircleMass(const(b2Circle)* shape, float density);

/// Compute mass properties of a capsule.
b2MassData b2ComputeCapsuleMass(const(b2Capsule)* shape, float density);

/// Compute mass properties of a polygon.
b2MassData b2ComputePolygonMass(const(b2Polygon)* shape, float density);

/// Compute the bounding box of a transformed circle.
b2AABB b2ComputeCircleAABB(const(b2Circle)* shape, b2WorldTransform transform);

/// Compute the bounding box of a transformed capsule.
b2AABB b2ComputeCapsuleAABB(const(b2Capsule)* shape, b2WorldTransform transform);

/// Compute the bounding box of a transformed polygon.
b2AABB b2ComputePolygonAABB(const(b2Polygon)* shape, b2WorldTransform transform);

/// Compute the bounding box of a transformed line segment.
b2AABB b2ComputeSegmentAABB(const(b2Segment)* shape, b2WorldTransform transform);

/// Test a point for overlap with a circle in local space.
bool b2PointInCircle(const(b2Circle)* shape, b2Vec2 point);

/// Test a point for overlap with a capsule in local space.
bool b2PointInCapsule(const(b2Capsule)* shape, b2Vec2 point);

/// Test a point for overlap with a convex polygon in local space.
bool b2PointInPolygon(const(b2Polygon)* shape, b2Vec2 point);

/// Ray cast versus circle shape in local space.
b2CastOutput b2RayCastCircle(const(b2Circle)* shape, const(b2RayCastInput)* input);

/// Ray cast versus capsule shape in local space.
b2CastOutput b2RayCastCapsule(const(b2Capsule)* shape, const(b2RayCastInput)* input);

/// Ray cast versus segment shape in local space. Optionally one-sided.
b2CastOutput b2RayCastSegment(const(b2Segment)* shape, const(b2RayCastInput)* input, bool oneSided);

/// Ray cast versus polygon shape in local space.
b2CastOutput b2RayCastPolygon(const(b2Polygon)* shape, const(b2RayCastInput)* input);

/// Shape cast versus a circle.
b2CastOutput b2ShapeCastCircle(const(b2Circle)* shape, const(b2ShapeCastInput)* input);

/// Shape cast versus a capsule.
b2CastOutput b2ShapeCastCapsule(const(b2Capsule)* shape, const(b2ShapeCastInput)* input);

/// Shape cast versus a line segment.
b2CastOutput b2ShapeCastSegment(const(b2Segment)* shape, const(b2ShapeCastInput)* input);

/// Shape cast versus a convex polygon.
b2CastOutput b2ShapeCastPolygon(const(b2Polygon)* shape, const(b2ShapeCastInput)* input);

/// Compute the convex hull of a set of points. Returns an empty hull if it fails.
b2Hull b2ComputeHull(const(b2Vec2)* points, int count);

/// Determine if a hull is valid. Expensive; do not call at runtime.
bool b2ValidateHull(const(b2Hull)* hull);

/// Compute the distance between two line segments, clamping at the end points if needed.
b2SegmentDistanceResult b2SegmentDistance(b2Vec2 p1, b2Vec2 q1, b2Vec2 p2, b2Vec2 q2);

/// Compute the closest points between two shapes represented as point clouds.
b2DistanceOutput b2ShapeDistance(const(b2DistanceInput)* input, b2SimplexCache* cache, b2Simplex* simplexes, int simplexCapacity);

/// Perform a linear shape cast of shape B moving and shape A fixed.
b2CastOutput b2ShapeCast(const(b2ShapeCastPairInput)* input);

/// Make a proxy for use in overlap, shape cast, and related functions. Deep-copies the points.
b2ShapeProxy b2MakeProxy(const(b2Vec2)* points, int count, float radius);

/// Make a proxy with a transform. Deep-copies the points.
b2ShapeProxy b2MakeOffsetProxy(const(b2Vec2)* points, int count, float radius, b2Vec2 position, b2Rot rotation);

/// Evaluate the transform sweep at a specific time.
b2Transform b2GetSweepTransform(const(b2Sweep)* sweep, float time);

/// Compute the upper bound on time before two shapes penetrate.
b2TOIOutput b2TimeOfImpact(const(b2TOIInput)* input);

/// Compute the contact manifold between two circles.
b2LocalManifold b2CollideCircles(const(b2Circle)* circleA, const(b2Circle)* circleB, b2Transform xf);

/// Compute the contact manifold between a capsule and circle.
b2LocalManifold b2CollideCapsuleAndCircle(const(b2Capsule)* capsuleA, const(b2Circle)* circleB, b2Transform xf);

/// Compute the contact manifold between a segment and a circle.
b2LocalManifold b2CollideSegmentAndCircle(const(b2Segment)* segmentA, const(b2Circle)* circleB, b2Transform xf);

/// Compute the contact manifold between a polygon and a circle.
b2LocalManifold b2CollidePolygonAndCircle(const(b2Polygon)* polygonA, const(b2Circle)* circleB, b2Transform xf);

/// Compute the contact manifold between two capsules.
b2LocalManifold b2CollideCapsules(const(b2Capsule)* capsuleA, const(b2Capsule)* capsuleB, b2Transform xf);

/// Compute the contact manifold between a segment and a capsule.
b2LocalManifold b2CollideSegmentAndCapsule(const(b2Segment)* segmentA, const(b2Capsule)* capsuleB, b2Transform xf);

/// Compute the contact manifold between a polygon and capsule.
b2LocalManifold b2CollidePolygonAndCapsule(const(b2Polygon)* polygonA, const(b2Capsule)* capsuleB, b2Transform xf);

/// Compute the contact manifold between two polygons.
b2LocalManifold b2CollidePolygons(const(b2Polygon)* polygonA, const(b2Polygon)* polygonB, b2Transform xf);

/// Compute the contact manifold between a segment and a polygon.
b2LocalManifold b2CollideSegmentAndPolygon(const(b2Segment)* segmentA, const(b2Polygon)* polygonB, b2Transform xf);

/// Compute the contact manifold between a chain segment and a circle.
b2LocalManifold b2CollideChainSegmentAndCircle(const(b2ChainSegment)* segmentA, const(b2Circle)* circleB, b2Transform xf);

/// Compute the contact manifold between a chain segment and a capsule.
b2LocalManifold b2CollideChainSegmentAndCapsule(const(b2ChainSegment)* segmentA, const(b2Capsule)* capsuleB,
        b2Transform xf, b2SimplexCache* cache);

/// Compute the contact manifold between a chain segment and a rounded polygon.
b2LocalManifold b2CollideChainSegmentAndPolygon(const(b2ChainSegment)* segmentA, const(b2Polygon)* polygonB,
        b2Transform xf, b2SimplexCache* cache);

/// Construct a dynamic tree, initializing the node pool.
b2DynamicTree b2DynamicTree_Create(int proxyCapacity);

/// Destroy the tree, freeing the node pool.
void b2DynamicTree_Destroy(b2DynamicTree* tree);

/// Create a proxy. Provide an AABB and a userData value.
int b2DynamicTree_CreateProxy(b2DynamicTree* tree, b2AABB aabb, ulong categoryBits, ulong userData);

/// Destroy a proxy. Asserts if the id is invalid.
void b2DynamicTree_DestroyProxy(b2DynamicTree* tree, int proxyId);

/// Move a proxy to a new AABB by removing and reinserting into the tree.
void b2DynamicTree_MoveProxy(b2DynamicTree* tree, int proxyId, b2AABB aabb);

/// Enlarge a proxy and enlarge ancestors as necessary.
void b2DynamicTree_EnlargeProxy(b2DynamicTree* tree, int proxyId, b2AABB aabb);

/// Modify the category bits on a proxy. This is an expensive operation.
void b2DynamicTree_SetCategoryBits(b2DynamicTree* tree, int proxyId, ulong categoryBits);

/// Get the category bits on a proxy.
ulong b2DynamicTree_GetCategoryBits(b2DynamicTree* tree, int proxyId);

/// Query an AABB for overlapping proxies.
b2TreeStats b2DynamicTree_Query(const(b2DynamicTree)* tree, b2AABB aabb, ulong maskBits,
        b2TreeQueryCallbackFcn callback, void* context);

/// Query an AABB for overlapping proxies. No filtering is performed.
b2TreeStats b2DynamicTree_QueryAll(const(b2DynamicTree)* tree, b2AABB aabb, b2TreeQueryCallbackFcn callback, void* context);

/// Ray cast against the proxies in the tree.
b2TreeStats b2DynamicTree_RayCast(const(b2DynamicTree)* tree, const(b2RayCastInput)* input, ulong maskBits,
        b2TreeRayCastCallbackFcn callback, void* context);

/// Cast a swept AABB through the tree.
b2TreeStats b2DynamicTree_BoxCast(const(b2DynamicTree)* tree, const(b2BoxCastInput)* input, ulong maskBits,
        b2TreeBoxCastCallbackFcn callback, void* context);

/// Get the height of the binary tree.
int b2DynamicTree_GetHeight(const(b2DynamicTree)* tree);

/// Get the ratio of the sum of the node areas to the root area.
float b2DynamicTree_GetAreaRatio(const(b2DynamicTree)* tree);

/// Get the bounding box that contains the entire tree.
b2AABB b2DynamicTree_GetRootBounds(const(b2DynamicTree)* tree);

/// Get the number of proxies created.
int b2DynamicTree_GetProxyCount(const(b2DynamicTree)* tree);

/// Rebuild the tree while retaining subtrees that haven't changed. Returns the number of boxes sorted.
int b2DynamicTree_Rebuild(b2DynamicTree* tree, bool fullBuild);

/// Get the number of bytes used by this tree.
int b2DynamicTree_GetByteCount(const(b2DynamicTree)* tree);

/// Get proxy user data.
ulong b2DynamicTree_GetUserData(const(b2DynamicTree)* tree, int proxyId);

/// Get the AABB of a proxy.
b2AABB b2DynamicTree_GetAABB(const(b2DynamicTree)* tree, int proxyId);

/// Validate this tree. For testing.
void b2DynamicTree_Validate(const(b2DynamicTree)* tree);

/// Validate this tree has no enlarged AABBs. For testing.
void b2DynamicTree_ValidateNoEnlarged(const(b2DynamicTree)* tree);

/// Solve the position of a mover that satisfies the given collision planes.
b2PlaneSolverResult b2SolvePlanes(b2Vec2 targetDelta, b2CollisionPlane* planes, int count);

/// Clip the velocity against the given collision planes.
b2Vec2 b2ClipVector(b2Vec2 vector, const(b2CollisionPlane)* planes, int count);
