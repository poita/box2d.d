// SPDX-License-Identifier: MIT
/++
    Public definitions: world/body/shape/joint definitions, events, callbacks,
    debug draw and colors.

    Translated from `box2d/types.h`.
+/
module box2d.types;

import box2d.id;
import box2d.math_functions;
import box2d.collision : b2Manifold, b2PlaneResult;

/// Default collision category bits (single bit set).
enum ulong B2_DEFAULT_CATEGORY_BITS = 1;

/// Default collision mask bits (collide with everything).
enum ulong B2_DEFAULT_MASK_BITS = ulong.max;

extern (C) nothrow:

// ---------------------------------------------------------------------------
// Task system callbacks
// ---------------------------------------------------------------------------

/// Prototype for a Box2D task. Run on a worker thread, exactly once per enqueue.
alias b2TaskCallbackFcn = void function(void* taskContext);

/// Spawn a task. Returns a pointer to the user's task object (may be null).
/// A null return indicates the work was executed serially within the callback.
alias b2EnqueueTaskCallbackFcn = void* function(b2TaskCallbackFcn task, void* taskContext, void* userContext);

/// Finish a user task object that wraps a Box2D task.
alias b2FinishTaskCallbackFcn = void function(void* userTask, void* userContext);

/// Optional friction mixing callback. Called from a worker thread; do not modify state.
alias b2FrictionCallbackFcn = float function(float frictionA, ulong userMaterialIdA, float frictionB, ulong userMaterialIdB);

/// Optional restitution mixing callback. Called from a worker thread; do not modify state.
alias b2RestitutionCallbackFcn = float function(float restitutionA, ulong userMaterialIdA,
        float restitutionB, ulong userMaterialIdB);

// ---------------------------------------------------------------------------
// World
// ---------------------------------------------------------------------------

/// Result from `b2World_RayCastClosest`.
struct b2RayResult
{
    b2ShapeId shapeId;
    b2Pos point;
    b2Vec2 normal;
    float fraction = 0;
    int nodeVisits;
    int leafVisits;
    bool hit;
}

/// Optional world capacities that can be used to avoid run-time allocations.
struct b2Capacity
{
    int staticShapeCount; /// Number of expected static shapes.
    int dynamicShapeCount; /// Number of expected dynamic and kinematic shapes.
    int staticBodyCount; /// Number of expected static bodies.
    int dynamicBodyCount; /// Number of expected dynamic and kinematic bodies.
    int contactCount; /// Number of expected contacts.
    int arenaByteCount; /// Reserve arena allocator space, used for temporary allocations.
}

/// World definition used to create a simulation world.
/// Must be initialized using `b2DefaultWorldDef`.
struct b2WorldDef
{
    b2Vec2 gravity;
    float restitutionThreshold = 0;
    /// Number of iterations of the restitution solver. More iterations can lead to less
    /// box spinning. See `B2_MAX_RESTITUTION_ITERATIONS`.
    int restitutionIterations;
    /// Enable full contact propagation in the restitution solver. Expensive. (Experimental)
    bool enableRestitutionPropagation;
    float hitEventThreshold = 0;
    float contactHertz = 0;
    float contactDampingRatio = 0;
    float contactSpeed = 0;
    float maximumLinearSpeed = 0;
    b2FrictionCallbackFcn frictionCallback;
    b2RestitutionCallbackFcn restitutionCallback;
    bool enableSleep;
    bool enableContinuous;
    int workerCount;
    b2EnqueueTaskCallbackFcn enqueueTask;
    b2FinishTaskCallbackFcn finishTask;
    void* userTaskContext;
    void* userData;
    b2Capacity capacity;
    int internalValue; /// Used internally to detect a valid definition. DO NOT SET.
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

/// The body simulation type.
enum b2BodyType
{
    b2_staticBody = 0, /// zero mass, zero velocity, may be manually moved
    b2_kinematicBody = 1, /// zero mass, velocity set by user, moved by solver
    b2_dynamicBody = 2, /// positive mass, velocity determined by forces, moved by solver
    b2_bodyTypeCount, /// number of body types
}

/// Motion locks to restrict the body movement.
struct b2MotionLocks
{
    bool linearX; /// Prevent translation along the x-axis
    bool linearY; /// Prevent translation along the y-axis
    bool angularZ; /// Prevent rotation around the z-axis
}

/// A body definition holds all the data needed to construct a rigid body.
/// Must be initialized using `b2DefaultBodyDef`.
struct b2BodyDef
{
    b2BodyType type;
    b2Pos position;
    b2Rot rotation;
    b2Vec2 linearVelocity;
    float angularVelocity = 0;
    float linearDamping = 0;
    float angularDamping = 0;
    float gravityScale = 0;
    float sleepThreshold = 0;
    /// Continuous collision safety factor. A body whose motion over one time step exceeds
    /// `safetyFactor` times its tunneling distance is treated as fast. Non-dimensional;
    /// recommended range [0.01, 0.5].
    float safetyFactor = 0;
    const(char)* name;
    void* userData;
    b2MotionLocks motionLocks;
    bool enableSleep;
    bool isAwake;
    bool isBullet;
    bool isEnabled;
    bool allowFastRotation;
    bool enableContactRecycling;
    int internalValue; /// Used internally to detect a valid definition. DO NOT SET.
}

// ---------------------------------------------------------------------------
// Shape
// ---------------------------------------------------------------------------

/// Collision filtering for shapes. Affects shape-vs-shape and shape-vs-query collision.
struct b2Filter
{
    ulong categoryBits; /// The collision category bits. Normally you would just set one bit.
    ulong maskBits; /// The categories this shape accepts for collision.
    int groupIndex; /// Never collide (negative) or always collide (positive) with the same group.
}

/// The query filter is used to filter collisions between queries and shapes.
struct b2QueryFilter
{
    ulong categoryBits; /// The collision category bits of this query.
    ulong maskBits; /// The shape categories this query accepts for collision.
}

/// Shape type.
enum b2ShapeType
{
    b2_circleShape, /// A circle with an offset
    b2_capsuleShape, /// A capsule is an extruded circle
    b2_segmentShape, /// A line segment
    b2_polygonShape, /// A convex polygon
    b2_chainSegmentShape, /// A line segment owned by a chain shape
    b2_shapeTypeCount, /// The number of shape types
}

/// Surface materials allow chain shapes to have per segment surface properties.
struct b2SurfaceMaterial
{
    float friction = 0; /// The Coulomb (dry) friction coefficient, usually in [0,1].
    float restitution = 0; /// The coefficient of restitution (bounce), usually in [0,1].
    float rollingResistance = 0; /// The rolling resistance, usually in [0,1].
    float tangentSpeed = 0; /// The tangent speed for conveyor belts.
    ulong userMaterialId; /// User material identifier passed with query results.
    uint customColor; /// Custom debug draw color.
}

/// Used to create a shape. Must be initialized using `b2DefaultShapeDef`.
struct b2ShapeDef
{
    void* userData;
    b2SurfaceMaterial material;
    float density = 0;
    b2Filter filter;
    bool enableCustomFiltering;
    bool isSensor;
    bool enableSensorEvents;
    bool enableContactEvents;
    bool enableHitEvents;
    bool enablePreSolveEvents;
    bool invokeContactCreation;
    bool updateBodyMass;
    int internalValue; /// Used internally to detect a valid definition. DO NOT SET.
}

/// Used to create a chain of line segments. Must be initialized using `b2DefaultChainDef`.
struct b2ChainDef
{
    void* userData;
    const(b2Vec2)* points;
    /// The point count. At least 2 for an open chain and at least 3 for a loop.
    int pointCount;
    /// Leading ghost point for an open chain. Ignored for loops.
    b2Vec2 ghost1;
    /// Ending ghost point for an open chain. Ignored for loops.
    b2Vec2 ghost2;
    const(b2SurfaceMaterial)* materials;
    int materialCount;
    b2Filter filter;
    bool isLoop;
    bool enableSensorEvents;
    int internalValue; /// Used internally to detect a valid definition. DO NOT SET.
}

/// Profiling data. Times are in milliseconds.
struct b2Profile
{
    float step = 0;
    float pairs = 0;
    float collide = 0;
    float solve = 0;
    float solverSetup = 0;
    float constraints = 0;
    float prepareConstraints = 0;
    float integrateVelocities = 0;
    float warmStart = 0;
    float solveImpulses = 0;
    float integratePositions = 0;
    float relaxImpulses = 0;
    float restitution = 0;
    float storeImpulses = 0;
    float splitIslands = 0;
    float transforms = 0;
    float sensorHits = 0;
    float jointEvents = 0;
    float hitEvents = 0;
    float refit = 0;
    float bullets = 0;
    float sleepIslands = 0;
    float sensors = 0;
}

/// Counters that give details of the simulation size.
struct b2Counters
{
    size_t byteCount;
    int bodyCount;
    int shapeCount;
    int contactCount;
    int jointCount;
    int islandCount;
    int stackUsed;
    int staticTreeHeight;
    int treeHeight;
    int taskCount;
    int[24] colorCounts;
    int awakeContactCount;
    int recycledContactCount;
}

// ---------------------------------------------------------------------------
// Joints
// ---------------------------------------------------------------------------

/// Joint type enumeration.
enum b2JointType
{
    b2_distanceJoint, /// constrain the distance between two points
    b2_filterJoint, /// filter collision between two bodies
    b2_motorJoint, /// fully control the movement of a body
    b2_moverJoint, /// control the movement of the dynamic character mover
    b2_pogoJoint, /// ground interaction for the dynamic character mover
    b2_prismaticJoint,
    b2_revoluteJoint,
    b2_weldJoint,
    b2_wheelJoint,
}

/// Base joint definition used by all joint types.
struct b2JointDef
{
    void* userData;
    b2BodyId bodyIdA;
    b2BodyId bodyIdB;
    b2Transform localFrameA;
    b2Transform localFrameB;
    float forceThreshold = 0;
    float torqueThreshold = 0;
    float constraintHertz = 0;
    float constraintDampingRatio = 0;
    float drawScale = 0;
    bool collideConnected;
}

/// Distance joint definition. Connects a point on body A with a point on body B by a segment.
struct b2DistanceJointDef
{
    b2JointDef base;
    float length = 0;
    bool enableSpring;
    float lowerSpringForce = 0;
    float upperSpringForce = 0;
    float hertz = 0;
    float dampingRatio = 0;
    bool enableLimit;
    float minLength = 0;
    float maxLength = 0;
    bool enableMotor;
    float maxMotorForce = 0;
    float motorSpeed = 0;
    int internalValue;
}

/// A motor joint controls the relative velocity and/or transform between two bodies.
struct b2MotorJointDef
{
    b2JointDef base;
    b2Vec2 linearVelocity;
    float maxVelocityForce = 0;
    float angularVelocity = 0;
    float maxVelocityTorque = 0;
    float linearHertz = 0;
    float linearDampingRatio = 0;
    float maxSpringForce = 0;
    float angularHertz = 0;
    float angularDampingRatio = 0;
    float maxSpringTorque = 0;
    int internalValue;
}

/// A filter joint disables collision between two specific bodies.
struct b2FilterJointDef
{
    b2JointDef base;
    int internalValue;
}

/// A mover joint moves a dynamic character mover through velocity commands. The x and y
/// directions are handled separately. Does not affect rotation.
struct b2MoverJointDef
{
    b2JointDef base;
    b2Vec2 linearVelocity; /// The desired linear velocity
    b2Vec2 maxVelocityForce; /// The maximum motor force in newtons
    int internalValue; /// Used internally to detect a valid definition. DO NOT SET.
}

/// Pogo joint definition: ground interaction for the dynamic character mover.
struct b2PogoJointDef
{
    b2JointDef base;
    b2Vec2 normal; /// Normal vector at the contact
    float hertz = 0; /// The spring stiffness Hertz, cycles per second
    float dampingRatio = 0; /// The spring damping ratio, non-dimensional
    float restLength = 0; /// Spring length
    float maxTensionForce = 0; /// Maximum tension force. Controls how sticky the mover is to ground.
    float maxCompressionForce = 0; /// Maximum compression force. How hard the pogo pushes the mover up.
    float impulse = 0; /// The initial pogo internal impulse, for smoother spring behavior when recreated
    float velocity = 0; /// The initial pogo internal velocity, for smoother spring behavior when recreated
    int internalValue; /// Used internally to detect a valid definition. DO NOT SET.
}

/// Prismatic joint definition. Body B slides along the x-axis in local frame A.
struct b2PrismaticJointDef
{
    b2JointDef base;
    bool enableSpring;
    float hertz = 0;
    float dampingRatio = 0;
    float targetTranslation = 0;
    bool enableLimit;
    float lowerTranslation = 0;
    float upperTranslation = 0;
    bool enableMotor;
    float maxMotorForce = 0;
    float motorSpeed = 0;
    int internalValue;
}

/// Revolute joint definition. A point on body B is fixed to a point on body A.
struct b2RevoluteJointDef
{
    b2JointDef base;
    float targetAngle = 0;
    bool enableSpring;
    float hertz = 0;
    float dampingRatio = 0;
    bool enableLimit;
    float lowerAngle = 0;
    float upperAngle = 0;
    bool enableMotor;
    float maxMotorTorque = 0;
    float motorSpeed = 0;
    int internalValue;
}

/// Weld joint definition. Connects two bodies together rigidly.
struct b2WeldJointDef
{
    b2JointDef base;
    float linearHertz = 0;
    float angularHertz = 0;
    float linearDampingRatio = 0;
    float angularDampingRatio = 0;
    int internalValue;
}

/// Wheel joint definition. Body B is a wheel that may rotate freely and slide along the x-axis.
struct b2WheelJointDef
{
    b2JointDef base;
    bool enableSpring;
    float hertz = 0;
    float dampingRatio = 0;
    bool enableLimit;
    float lowerTranslation = 0;
    float upperTranslation = 0;
    bool enableMotor;
    float maxMotorTorque = 0;
    float motorSpeed = 0;
    int internalValue;
}

/// The explosion definition configures options for explosions.
struct b2ExplosionDef
{
    ulong maskBits;
    b2Pos position;
    float radius = 0;
    float falloff = 0;
    float impulsePerLength = 0;
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/// Generated when a shape starts to overlap a sensor shape.
struct b2SensorBeginTouchEvent
{
    b2ShapeId sensorShapeId;
    b2ShapeId visitorShapeId;
}

/// Generated when a shape stops overlapping a sensor shape.
struct b2SensorEndTouchEvent
{
    b2ShapeId sensorShapeId;
    b2ShapeId visitorShapeId;
}

/// Sensor events buffered in the world, available after the time step.
struct b2SensorEvents
{
    b2SensorBeginTouchEvent* beginEvents;
    b2SensorEndTouchEvent* endEvents;
    int beginCount;
    int endCount;
}

/// Generated when two shapes begin touching.
struct b2ContactBeginTouchEvent
{
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
    b2ContactId contactId;
}

/// Generated when two shapes stop touching.
struct b2ContactEndTouchEvent
{
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
    b2ContactId contactId;
}

/// Generated when two shapes collide faster than the hit speed threshold.
struct b2ContactHitEvent
{
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
    b2ContactId contactId;
    b2Pos point;
    b2Vec2 normal;
    float approachSpeed = 0;
}

/// Contact events buffered in the world, available after the time step.
struct b2ContactEvents
{
    b2ContactBeginTouchEvent* beginEvents;
    b2ContactEndTouchEvent* endEvents;
    b2ContactHitEvent* hitEvents;
    int beginCount;
    int endCount;
    int hitCount;
}

/// Triggered when a body moves due to simulation.
struct b2BodyMoveEvent
{
    void* userData;
    b2WorldTransform transform;
    b2BodyId bodyId;
    bool fellAsleep;
}

/// Body events buffered in the world, available after the time step.
struct b2BodyEvents
{
    b2BodyMoveEvent* moveEvents;
    int moveCount;
}

/// Reports joints that are awake and exceed the force and/or torque threshold.
struct b2JointEvent
{
    b2JointId jointId;
    void* userData;
}

/// Joint events buffered in the world, available after the time step.
struct b2JointEvents
{
    b2JointEvent* jointEvents;
    int count;
}

/// The contact data for two shapes. The manifold normal points from shape A to shape B.
struct b2ContactData
{
    b2ContactId contactId;
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
    b2Manifold manifold;
}

// ---------------------------------------------------------------------------
// Query / simulation callbacks
// ---------------------------------------------------------------------------

/// Contact filter callback. Return false to disable the collision. Must be thread-safe.
alias b2CustomFilterCallbackFcn = bool function(b2ShapeId shapeIdA, b2ShapeId shapeIdB, void* context);

/// Pre-solve callback, called after a contact manifold is updated and before it goes to the
/// solver. You may carefully modify the manifold; set its point count to zero to disable the
/// collision. Must be thread-safe; do not modify the world inside it.
alias b2PreSolveCallbackFcn = void function(b2ShapeId shapeIdA, b2ShapeId shapeIdB, b2Manifold* manifold, void* context);

/// Pre-continuous callback, called when continuous collision computes a time of impact event.
/// Return false to skip the event. Must be thread-safe; do not modify the world inside it.
alias b2PreContinuousCallbackFcn = bool function(b2ShapeId shapeIdA, b2ShapeId shapeIdB, b2Pos point,
        b2Vec2 normal, void* context);

/// Overlap query callback. Return false to terminate the query.
alias b2OverlapResultCallbackFcn = bool function(b2ShapeId shapeId, void* context);

/// Ray and shape cast callback. Return -1 to filter, 0 to terminate, a fraction to clip, 1 to continue.
alias b2CastResultCallbackFcn = float function(b2ShapeId shapeId, b2Pos point, b2Vec2 normal, float fraction, void* context);

/// Collects collision planes for character movers. Return true to continue gathering planes.
alias b2PlaneResultCallbackFcn = bool function(b2ShapeId shapeId, const(b2PlaneResult)* plane, void* context);

// ---------------------------------------------------------------------------
// Debug draw
// ---------------------------------------------------------------------------

/// Named colors for debug draw, mostly matching the named SVG colors.
enum b2HexColor
{
    b2_colorAliceBlue = 0xF0F8FF,
    b2_colorAntiqueWhite = 0xFAEBD7,
    b2_colorAqua = 0x00FFFF,
    b2_colorAquamarine = 0x7FFFD4,
    b2_colorAzure = 0xF0FFFF,
    b2_colorBeige = 0xF5F5DC,
    b2_colorBisque = 0xFFE4C4,
    b2_colorBlack = 0x000000,
    b2_colorBlanchedAlmond = 0xFFEBCD,
    b2_colorBlue = 0x0000FF,
    b2_colorBlueViolet = 0x8A2BE2,
    b2_colorBrown = 0xA52A2A,
    b2_colorBurlywood = 0xDEB887,
    b2_colorCadetBlue = 0x5F9EA0,
    b2_colorChartreuse = 0x7FFF00,
    b2_colorChocolate = 0xD2691E,
    b2_colorCoral = 0xFF7F50,
    b2_colorCornflowerBlue = 0x6495ED,
    b2_colorCornsilk = 0xFFF8DC,
    b2_colorCrimson = 0xDC143C,
    b2_colorCyan = 0x00FFFF,
    b2_colorDarkBlue = 0x00008B,
    b2_colorDarkCyan = 0x008B8B,
    b2_colorDarkGoldenRod = 0xB8860B,
    b2_colorDarkGray = 0xA9A9A9,
    b2_colorDarkGreen = 0x006400,
    b2_colorDarkKhaki = 0xBDB76B,
    b2_colorDarkMagenta = 0x8B008B,
    b2_colorDarkOliveGreen = 0x556B2F,
    b2_colorDarkOrange = 0xFF8C00,
    b2_colorDarkOrchid = 0x9932CC,
    b2_colorDarkRed = 0x8B0000,
    b2_colorDarkSalmon = 0xE9967A,
    b2_colorDarkSeaGreen = 0x8FBC8F,
    b2_colorDarkSlateBlue = 0x483D8B,
    b2_colorDarkSlateGray = 0x2F4F4F,
    b2_colorDarkTurquoise = 0x00CED1,
    b2_colorDarkViolet = 0x9400D3,
    b2_colorDeepPink = 0xFF1493,
    b2_colorDeepSkyBlue = 0x00BFFF,
    b2_colorDimGray = 0x696969,
    b2_colorDodgerBlue = 0x1E90FF,
    b2_colorFireBrick = 0xB22222,
    b2_colorFloralWhite = 0xFFFAF0,
    b2_colorForestGreen = 0x228B22,
    b2_colorFuchsia = 0xFF00FF,
    b2_colorGainsboro = 0xDCDCDC,
    b2_colorGhostWhite = 0xF8F8FF,
    b2_colorGold = 0xFFD700,
    b2_colorGoldenRod = 0xDAA520,
    b2_colorGray = 0x808080,
    b2_colorGreen = 0x008000,
    b2_colorGreenYellow = 0xADFF2F,
    b2_colorHoneyDew = 0xF0FFF0,
    b2_colorHotPink = 0xFF69B4,
    b2_colorIndianRed = 0xCD5C5C,
    b2_colorIndigo = 0x4B0082,
    b2_colorIvory = 0xFFFFF0,
    b2_colorKhaki = 0xF0E68C,
    b2_colorLavender = 0xE6E6FA,
    b2_colorLavenderBlush = 0xFFF0F5,
    b2_colorLawnGreen = 0x7CFC00,
    b2_colorLemonChiffon = 0xFFFACD,
    b2_colorLightBlue = 0xADD8E6,
    b2_colorLightCoral = 0xF08080,
    b2_colorLightCyan = 0xE0FFFF,
    b2_colorLightGoldenRodYellow = 0xFAFAD2,
    b2_colorLightGray = 0xD3D3D3,
    b2_colorLightGreen = 0x90EE90,
    b2_colorLightPink = 0xFFB6C1,
    b2_colorLightSalmon = 0xFFA07A,
    b2_colorLightSeaGreen = 0x20B2AA,
    b2_colorLightSkyBlue = 0x87CEFA,
    b2_colorLightSlateGray = 0x778899,
    b2_colorLightSteelBlue = 0xB0C4DE,
    b2_colorLightYellow = 0xFFFFE0,
    b2_colorLime = 0x00FF00,
    b2_colorLimeGreen = 0x32CD32,
    b2_colorLinen = 0xFAF0E6,
    b2_colorMagenta = 0xFF00FF,
    b2_colorMaroon = 0x800000,
    b2_colorMediumAquaMarine = 0x66CDAA,
    b2_colorMediumBlue = 0x0000CD,
    b2_colorMediumOrchid = 0xBA55D3,
    b2_colorMediumPurple = 0x9370DB,
    b2_colorMediumSeaGreen = 0x3CB371,
    b2_colorMediumSlateBlue = 0x7B68EE,
    b2_colorMediumSpringGreen = 0x00FA9A,
    b2_colorMediumTurquoise = 0x48D1CC,
    b2_colorMediumVioletRed = 0xC71585,
    b2_colorMidnightBlue = 0x191970,
    b2_colorMintCream = 0xF5FFFA,
    b2_colorMistyRose = 0xFFE4E1,
    b2_colorMoccasin = 0xFFE4B5,
    b2_colorNavajoWhite = 0xFFDEAD,
    b2_colorNavy = 0x000080,
    b2_colorOldLace = 0xFDF5E6,
    b2_colorOlive = 0x808000,
    b2_colorOliveDrab = 0x6B8E23,
    b2_colorOrange = 0xFFA500,
    b2_colorOrangeRed = 0xFF4500,
    b2_colorOrchid = 0xDA70D6,
    b2_colorPaleGoldenRod = 0xEEE8AA,
    b2_colorPaleGreen = 0x98FB98,
    b2_colorPaleTurquoise = 0xAFEEEE,
    b2_colorPaleVioletRed = 0xDB7093,
    b2_colorPapayaWhip = 0xFFEFD5,
    b2_colorPeachPuff = 0xFFDAB9,
    b2_colorPeru = 0xCD853F,
    b2_colorPink = 0xFFC0CB,
    b2_colorPlum = 0xDDA0DD,
    b2_colorPowderBlue = 0xB0E0E6,
    b2_colorPurple = 0x800080,
    b2_colorRebeccaPurple = 0x663399,
    b2_colorRed = 0xFF0000,
    b2_colorRosyBrown = 0xBC8F8F,
    b2_colorRoyalBlue = 0x4169E1,
    b2_colorSaddleBrown = 0x8B4513,
    b2_colorSalmon = 0xFA8072,
    b2_colorSandyBrown = 0xF4A460,
    b2_colorSeaGreen = 0x2E8B57,
    b2_colorSeaShell = 0xFFF5EE,
    b2_colorSienna = 0xA0522D,
    b2_colorSilver = 0xC0C0C0,
    b2_colorSkyBlue = 0x87CEEB,
    b2_colorSlateBlue = 0x6A5ACD,
    b2_colorSlateGray = 0x708090,
    b2_colorSnow = 0xFFFAFA,
    b2_colorSpringGreen = 0x00FF7F,
    b2_colorSteelBlue = 0x4682B4,
    b2_colorTan = 0xD2B48C,
    b2_colorTeal = 0x008080,
    b2_colorThistle = 0xD8BFD8,
    b2_colorTomato = 0xFF6347,
    b2_colorTurquoise = 0x40E0D0,
    b2_colorViolet = 0xEE82EE,
    b2_colorWheat = 0xF5DEB3,
    b2_colorWhite = 0xFFFFFF,
    b2_colorWhiteSmoke = 0xF5F5F5,
    b2_colorYellow = 0xFFFF00,
    b2_colorYellowGreen = 0x9ACD32,

    b2_colorBox2DRed = 0xDC3132,
    b2_colorBox2DBlue = 0x30AEBF,
    b2_colorBox2DGreen = 0x8CC924,
    b2_colorBox2DYellow = 0xFFEE8C,
}

/// Callbacks you can implement to draw a Box2D world. Initialize with `b2DefaultDebugDraw`.
struct b2DebugDraw
{
    /// Draw a closed polygon provided in CCW order.
    void function(b2WorldTransform transform, const(b2Vec2)* vertices, int vertexCount, b2HexColor color, void* context) DrawPolygonFcn;

    /// Draw a solid closed polygon provided in CCW order.
    void function(b2WorldTransform transform, const(b2Vec2)* vertices, int vertexCount, float radius,
            b2HexColor color, void* context) DrawSolidPolygonFcn;

    /// Draw a circle.
    void function(b2Pos center, float radius, b2HexColor color, void* context) DrawCircleFcn;

    /// Draw a solid circle.
    void function(b2WorldTransform transform, b2Vec2 center, float radius, b2HexColor color, void* context) DrawSolidCircleFcn;

    /// Draw a solid capsule.
    void function(b2Pos p1, b2Pos p2, float radius, b2HexColor color, void* context) DrawSolidCapsuleFcn;

    /// Draw a line segment.
    void function(b2Pos p1, b2Pos p2, b2HexColor color, void* context) DrawLineFcn;

    /// Draw a transform. Choose your own length scale.
    void function(b2WorldTransform transform, void* context) DrawTransformFcn;

    /// Draw a point.
    void function(b2Pos p, float size, b2HexColor color, void* context) DrawPointFcn;

    /// Draw a string in world space.
    void function(b2Pos p, const(char)* s, b2HexColor color, void* context) DrawStringFcn;

    /// Draw a bounding box.
    void function(b2AABB aabb, b2HexColor color, void* context) DrawBoundsFcn;

    b2AABB drawingBounds; /// World bounds to use for debug draw
    float forceScale = 0; /// Scale to use when drawing forces
    float jointScale = 0; /// Global scaling for joint drawing
    bool drawContacts; /// Option to draw contact points
    bool drawAnchorA; /// Draw anchor A for contact points (instead of anchorB)
    bool drawShapes; /// Option to draw shapes
    bool drawChainNormals; /// Option to draw chain shape normals
    bool drawJoints; /// Option to draw joints
    bool drawJointExtras; /// Option to draw additional information for joints
    bool drawBounds; /// Option to draw the bounding boxes for shapes
    bool drawMass; /// Option to draw the mass and center of mass of dynamic bodies
    bool drawBodyNames; /// Option to draw body names
    bool drawGraphColors; /// Option to visualize the graph coloring used for contacts and joints
    bool drawContactFeatures; /// Option to draw contact feature ids
    bool drawContactNormals; /// Option to draw contact normals
    bool drawContactForces; /// Option to draw contact normal forces
    bool drawFrictionForces; /// Option to draw contact friction forces
    bool drawIslands; /// Option to draw islands as bounding boxes
    void* context; /// User context passed to drawing callback functions
}

// ---------------------------------------------------------------------------
// Default initializers (exported)
// ---------------------------------------------------------------------------

@nogc:

/// Use this to initialize your world definition.
b2WorldDef b2DefaultWorldDef();

/// Use this to initialize your body definition.
b2BodyDef b2DefaultBodyDef();

/// Use this to initialize your collision filter.
b2Filter b2DefaultFilter();

/// Use this to initialize your query filter.
b2QueryFilter b2DefaultQueryFilter();

/// Use this to initialize your surface material.
b2SurfaceMaterial b2DefaultSurfaceMaterial();

/// Use this to initialize your shape definition.
b2ShapeDef b2DefaultShapeDef();

/// Use this to initialize your chain definition.
b2ChainDef b2DefaultChainDef();

/// Use this to initialize your distance joint definition.
b2DistanceJointDef b2DefaultDistanceJointDef();

/// Use this to initialize your motor joint definition.
b2MotorJointDef b2DefaultMotorJointDef();

/// Use this to initialize your filter joint definition.
b2FilterJointDef b2DefaultFilterJointDef();

/// Use this to initialize your mover joint definition.
b2MoverJointDef b2DefaultMoverJointDef();

/// Use this to initialize your pogo joint definition.
b2PogoJointDef b2DefaultPogoJointDef();

/// Use this to initialize your prismatic joint definition.
b2PrismaticJointDef b2DefaultPrismaticJointDef();

/// Use this to initialize your revolute joint definition.
b2RevoluteJointDef b2DefaultRevoluteJointDef();

/// Use this to initialize your weld joint definition.
b2WeldJointDef b2DefaultWeldJointDef();

/// Use this to initialize your wheel joint definition.
b2WheelJointDef b2DefaultWheelJointDef();

/// Use this to initialize your explosion definition.
b2ExplosionDef b2DefaultExplosionDef();

/// Get the visualization color assigned to a constraint graph color slot.
b2HexColor b2GetGraphColor(int index);

/// Use this to initialize your drawing interface.
b2DebugDraw b2DefaultDebugDraw();
