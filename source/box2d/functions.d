// SPDX-License-Identifier: MIT
/++
    The main Box2D API: world, body, shape, chain, joint, contact and
    recording/replay functions.

    Translated from `box2d/box2d.h`.
+/
module box2d.functions;

public import box2d.base;
public import box2d.id;
public import box2d.math_functions;
public import box2d.collision;
public import box2d.types;

// ---------------------------------------------------------------------------
// Recording / replay types (opaque handles and metadata)
// ---------------------------------------------------------------------------

/// Opaque handle to a simulation recording.
struct b2Recording;

/// Opaque handle for incremental playback of a recording.
struct b2RecPlayer;

/// Static metadata describing a recording, resolved once when the player opens the file.
struct b2RecPlayerInfo
{
    int frameCount; /// total recorded steps
    int workerCount; /// worker count used for the replay world
    float timeStep = 0; /// dt of the recorded steps
    int subStepCount; /// recorded sub-steps
    float lengthScale = 0; /// length units per meter in effect when recorded
    b2AABB bounds; /// accumulated world bounds over the recording
}

/// The kind of a recorded spatial query, matching the public query and cast functions.
enum b2RecQueryType
{
    b2_recQueryOverlapAABB,
    b2_recQueryOverlapShape,
    b2_recQueryCastRay,
    b2_recQueryCastShape,
    b2_recQueryCollideMover,
    b2_recQueryCastRayClosest,
    b2_recQueryCastMover,
    b2_recQueryShapeTestPoint,
    b2_recQueryShapeRayCast,
}

/// A spatial query recorded during a replayed frame, exposed for inspection.
struct b2RecQueryInfo
{
    b2RecQueryType type;
    b2QueryFilter filter; /// zeroed for the shape local query types
    b2AABB aabb; /// overlap AABB, relative to origin
    b2Pos origin; /// query origin
    b2Vec2 translation; /// ray and cast translation
    b2ShapeId shape; /// target shape for the shape local query types
    int hitCount; /// number of recorded results
}

/// One result of a recorded spatial query.
struct b2RecQueryHit
{
    b2ShapeId shape;
    b2Pos point;
    b2Vec2 normal;
    float fraction = 0;
}

// ---------------------------------------------------------------------------
// Functions
//
// In the default single-precision build `b2CreateWorld` is a real exported
// symbol. (In BOX2D_DOUBLE_PRECISION builds the C header remaps it to
// b2CreateWorldDoublePrecision; this binding targets single precision.)
// ---------------------------------------------------------------------------

extern (C) nothrow @nogc:

/// Create a world for rigid body simulation. A world contains bodies, shapes, and constraints. You make create
/// up to 128 worlds. Each world is completely independent and may be simulated in parallel.
/// @return the world id.
b2WorldId b2CreateWorld(const(b2WorldDef)* def);

/// Destroy a world
void b2DestroyWorld(b2WorldId worldId);

/// World id validation. Provides validation for up to 64K allocations.
bool b2World_IsValid(b2WorldId id);

/// Simulate a world for one time step. This performs collision detection, integration, and constraint solution.
/// @param worldId The world to simulate
/// @param timeStep The amount of time to simulate, this should be a fixed number. Usually 1/60.
/// @param subStepCount The number of sub-steps, increasing the sub-step count can increase accuracy. Usually 4.
void b2World_Step(b2WorldId worldId, float timeStep, int subStepCount);

/// Call this to draw shapes and other debug draw data
void b2World_Draw(b2WorldId worldId, b2DebugDraw* draw);

/// Call this to get the world bounds based on the union of all shape bounds.
b2AABB b2World_GetBounds(b2WorldId worldId);

/// Get the body events for the current time step. The event data is transient. Do not store a reference to this data.
b2BodyEvents b2World_GetBodyEvents(b2WorldId worldId);

/// Get sensor events for the current time step. The event data is transient. Do not store a reference to this data.
b2SensorEvents b2World_GetSensorEvents(b2WorldId worldId);

/// Get contact events for this current time step. The event data is transient. Do not store a reference to this data.
b2ContactEvents b2World_GetContactEvents(b2WorldId worldId);

/// Get the joint events for the current time step. The event data is transient. Do not store a reference to this data.
b2JointEvents b2World_GetJointEvents(b2WorldId worldId);

/// Overlap test for all shapes that *potentially* overlap the provided AABB.
/// The AABB is relative to the origin, which keeps the test precise far from the world origin
/// in large world mode. Near the origin pass b2Pos_zero and a world AABB.
b2TreeStats b2World_OverlapAABB(b2WorldId worldId, b2Pos origin, b2AABB aabb, b2QueryFilter filter,
        b2OverlapResultFcn fcn, void* context);

/// Overlap test for all shapes that overlap the provided shape proxy.
/// The proxy points are relative to the origin. Near the origin pass b2Pos_zero and world points.
b2TreeStats b2World_OverlapShape(b2WorldId worldId, b2Pos origin, const(b2ShapeProxy)* proxy,
        b2QueryFilter filter, b2OverlapResultFcn fcn, void* context);

/// Cast a ray into the world to collect shapes in the path of the ray.
/// Your callback function controls whether you get the closest point, any point, or n-points.
/// @note The callback function may receive shapes in any order
/// @param worldId The world to cast the ray against
/// @param origin The start point of the ray
/// @param translation The translation of the ray from the start point to the end point
/// @param filter Contains bit flags to filter unwanted shapes from the results
/// @param fcn A user implemented callback function
/// @param context A user context that is passed along to the callback function
///	@return traversal performance counters
b2TreeStats b2World_CastRay(b2WorldId worldId, b2Pos origin, b2Vec2 translation, b2QueryFilter filter,
        b2CastResultFcn fcn, void* context);

/// Cast a ray into the world to collect the closest hit. This is a convenience function. Ignores initial overlap.
/// This is less general than b2World_CastRay() and does not allow for custom filtering.
b2RayResult b2World_CastRayClosest(b2WorldId worldId, b2Pos origin, b2Vec2 translation, b2QueryFilter filter);

/// Cast a shape through the world. Similar to a cast ray except that a shape is cast instead of a point.
/// The proxy points are relative to the origin. Callback points are world positions.
///	@see b2World_CastRay
b2TreeStats b2World_CastShape(b2WorldId worldId, b2Pos origin, const(b2ShapeProxy)* proxy, b2Vec2 translation,
        b2QueryFilter filter, b2CastResultFcn fcn, void* context);

/// Cast a capsule mover through the world. This is a special shape cast that handles sliding along other shapes while reducing
/// clipping. The mover capsule is relative to the origin. Near the origin pass b2Pos_zero and a world capsule.
float b2World_CastMover(b2WorldId worldId, b2Pos origin, const(b2Capsule)* mover, b2Vec2 translation, b2QueryFilter filter);

/// Collide a capsule mover with the world, gathering collision planes that can be fed to b2SolvePlanes. Useful for
/// kinematic character movement. The mover capsule and the resulting planes are relative to the origin.
void b2World_CollideMover(b2WorldId worldId, b2Pos origin, const(b2Capsule)* mover, b2QueryFilter filter,
        b2PlaneResultFcn fcn, void* context);

/// Enable/disable sleep. If your application does not need sleeping, you can gain some performance
/// by disabling sleep completely at the world level.
/// @see b2WorldDef
void b2World_EnableSleeping(b2WorldId worldId, bool flag);

/// Is body sleeping enabled?
bool b2World_IsSleepingEnabled(b2WorldId worldId);

/// Enable/disable continuous collision between dynamic and static bodies. Generally you should keep continuous
/// collision enabled to prevent fast moving objects from going through static objects. The performance gain from
/// disabling continuous collision is minor.
/// @see b2WorldDef
void b2World_EnableContinuous(b2WorldId worldId, bool flag);

/// Is continuous collision enabled?
bool b2World_IsContinuousEnabled(b2WorldId worldId);

/// Adjust the restitution threshold. It is recommended not to make this value very small
/// because it will prevent bodies from sleeping. Usually in meters per second.
/// @see b2WorldDef
void b2World_SetRestitutionThreshold(b2WorldId worldId, float value);

/// Get the the restitution speed threshold. Usually in meters per second.
float b2World_GetRestitutionThreshold(b2WorldId worldId);

/// Adjust the hit event threshold. This controls the collision speed needed to generate a b2ContactHitEvent.
/// Usually in meters per second.
/// @see b2WorldDef::hitEventThreshold
void b2World_SetHitEventThreshold(b2WorldId worldId, float value);

/// Get the the hit event speed threshold. Usually in meters per second.
float b2World_GetHitEventThreshold(b2WorldId worldId);

/// Register the custom filter callback. This is optional.
void b2World_SetCustomFilterCallback(b2WorldId worldId, b2CustomFilterFcn fcn, void* context);

/// Register the pre-solve callback. This is optional.
void b2World_SetPreSolveCallback(b2WorldId worldId, b2PreSolveFcn fcn, void* context);

/// Set the gravity vector for the entire world. Box2D has no concept of an up direction and this
/// is left as a decision for the application. Usually in m/s^2.
/// @see b2WorldDef
void b2World_SetGravity(b2WorldId worldId, b2Vec2 gravity);

/// Get the gravity vector
b2Vec2 b2World_GetGravity(b2WorldId worldId);

/// Apply a radial explosion
/// @param worldId The world id
/// @param explosionDef The explosion definition
void b2World_Explode(b2WorldId worldId, const(b2ExplosionDef)* explosionDef);

/// Adjust contact tuning parameters
/// @param worldId The world id
/// @param hertz The contact stiffness (cycles per second)
/// @param dampingRatio The contact bounciness with 1 being critical damping (non-dimensional)
/// @param pushSpeed The maximum contact constraint push out speed (meters per second)
/// @note Advanced feature
void b2World_SetContactTuning(b2WorldId worldId, float hertz, float dampingRatio, float pushSpeed);

/// Set the contact point recycling distance. Setting this to zero disables contact point recycling.
/// Usually in meters.
void b2World_SetContactRecycleDistance(b2WorldId worldId, float recycleDistance);

/// Get the contact point recycling distance. Usually in meters.
float b2World_GetContactRecycleDistance(b2WorldId worldId);

/// Set the maximum linear speed. Usually in m/s.
void b2World_SetMaximumLinearSpeed(b2WorldId worldId, float maximumLinearSpeed);

/// Get the maximum linear speed. Usually in m/s.
float b2World_GetMaximumLinearSpeed(b2WorldId worldId);

/// Enable/disable constraint warm starting. Advanced feature for testing. Disabling
/// warm starting greatly reduces stability and provides no performance gain.
void b2World_EnableWarmStarting(b2WorldId worldId, bool flag);

/// Is constraint warm starting enabled?
bool b2World_IsWarmStartingEnabled(b2WorldId worldId);

/// Get the number of awake bodies.
int b2World_GetAwakeBodyCount(b2WorldId worldId);

/// Get the current world performance profile
b2Profile b2World_GetProfile(b2WorldId worldId);

/// Get world counters and sizes
b2Counters b2World_GetCounters(b2WorldId worldId);

/// Get max capacity. This can be used with b2WorldDef to avoid run-time allocations and copies
b2Capacity b2World_GetMaxCapacity(b2WorldId worldId);

/// Set the user data pointer.
void b2World_SetUserData(b2WorldId worldId, void* userData);

/// Get the user data pointer.
void* b2World_GetUserData(b2WorldId worldId);

/// Set the friction callback. Passing NULL resets to default.
void b2World_SetFrictionCallback(b2WorldId worldId, b2FrictionCallback callback);

/// Set the restitution callback. Passing NULL resets to default.
void b2World_SetRestitutionCallback(b2WorldId worldId, b2RestitutionCallback callback);

/// Set the worker count. Must be between in the range [1, B2_MAX_WORKERS]
void b2World_SetWorkerCount(b2WorldId worldId, int count);

/// Get the worker count.
int b2World_GetWorkerCount(b2WorldId worldId);

/// Dump memory stats to box2d_memory.txt
void b2World_DumpMemoryStats(b2WorldId worldId);

/// This is for internal testing
void b2World_RebuildStaticTree(b2WorldId worldId);

/// This is for internal testing
void b2World_EnableSpeculative(b2WorldId worldId, bool flag);

/// Create a recording buffer. The buffer grows on demand. @p byteCapacity pre-sizes it to avoid
/// reallocations during a known-length session. Pass 0 for a small default.
/// @return A recording handle, freed with b2DestroyRecording
b2Recording* b2CreateRecording(int byteCapacity);

/// Destroy a recording buffer and free its memory.
void b2DestroyRecording(b2Recording* recording);

/// Get a pointer to the recorded bytes, for saving to a file or transmitting. Valid until the
/// next recording call or b2DestroyRecording.
const(ubyte)* b2Recording_GetData(const(b2Recording)* recording);

/// Get the number of recorded bytes.
int b2Recording_GetSize(const(b2Recording)* recording);

/// Begin recording the world into @p recording. Serializes a snapshot of the current world as the
/// seed, then logs every mutating call. Call at a step boundary, before or after creating bodies.
/// Start before the first step to capture the whole session. No effect if already recording or if
/// the world is locked.
/// @param worldId The world to record
/// @param recording A recording buffer from b2CreateRecording
void b2World_StartRecording(b2WorldId worldId, b2Recording* recording);

/// Stop recording. The recording buffer keeps its bytes. Save and destroy it yourself.
/// @param worldId The world being recorded
void b2World_StopRecording(b2WorldId worldId);

/// Save a recording buffer to a file. Convenience wrapper over your own file I/O.
/// @return false if the file could not be written
bool b2SaveRecordingToFile(const(b2Recording)* recording, const(char)* path);

/// Load a recording from a file into a new recording buffer. Convenience wrapper over your own
/// file I/O. Destroy the result with b2DestroyRecording.
/// @return NULL if the file is missing or unreadable
b2Recording* b2LoadRecordingFromFile(const(char)* path);

/// Write a snapshot of the world's simulation state into a caller-owned buffer.
/// Call once with image == NULL to get the required size, then again with a buffer
/// of at least that size. Must be called at a step boundary.
/// @param worldId The world to snapshot
/// @param image Destination buffer, or NULL to query the size
/// @param capacity Size of image in bytes, ignored when querying
/// @return The number of bytes the snapshot needs. If it exceeds capacity nothing is written.
///         Returns 0 if the world is mid-step.
int b2World_Snapshot(b2WorldId worldId, ubyte* image, int capacity);

/// Restore a world's simulation state from a snapshot image, in place. The world keeps
/// its slot and generation, so this b2WorldId and any ids held from this same world stay
/// valid for objects that existed at the snapshot instant. Host wiring is preserved.
/// Restore into the same world the snapshot came from to keep held ids valid. Must be
/// called at a step boundary.
/// @param worldId The world to restore into
/// @param image A snapshot image produced by b2World_Snapshot
/// @param size Size of image in bytes
/// @return true on success. On a rejected image (bad magic, version, or layout) the world
///         is left unchanged. A corrupt payload detected after the rebuild begins returns
///         false and leaves the world unusable, so the caller must destroy it.
bool b2World_Restore(b2WorldId worldId, const(ubyte)* image, int size);

/// Create a new world from a snapshot image. Use this to load a saved world when there is
/// no existing world to restore into. The new world gets a fresh slot and id, so ids held
/// from the origin world will not match it. Host wiring is reset to defaults.
/// @param image A snapshot image produced by b2World_Snapshot
/// @param size Size of image in bytes
/// @param workerCount Worker count for the new world. 0 uses the serial single-worker fallback.
/// @return The new world id, or b2_nullWorldId on failure.
b2WorldId b2CreateWorldFromSnapshot(const(ubyte)* image, int size, int workerCount);

/// Create a rigid body given a definition. No reference to the definition is retained. So you can create the definition
/// on the stack and pass it as a pointer.
/// @code{.c}
/// b2BodyDef bodyDef = b2DefaultBodyDef();
/// b2BodyId myBodyId = b2CreateBody(myWorldId, &bodyDef);
/// @endcode
/// @warning This function is locked during callbacks.
b2BodyId b2CreateBody(b2WorldId worldId, const(b2BodyDef)* def);

/// Destroy a rigid body given an id. This destroys all shapes and joints attached to the body.
/// Do not keep references to the associated shapes and joints.
void b2DestroyBody(b2BodyId bodyId);

/// Body identifier validation. A valid body exists in a world and is non-null.
/// This can be used to detect orphaned ids. Provides validation for up to 64K allocations.
bool b2Body_IsValid(b2BodyId id);

/// Get the body type: static, kinematic, or dynamic
b2BodyType b2Body_GetType(b2BodyId bodyId);

/// Change the body type. This is an expensive operation. This automatically updates the mass
/// properties regardless of the automatic mass setting.
void b2Body_SetType(b2BodyId bodyId, b2BodyType type);

/// Set the body name. Up to 31 characters excluding 0 termination.
void b2Body_SetName(b2BodyId bodyId, const(char)* name);

/// Get the body name.
const(char)* b2Body_GetName(b2BodyId bodyId);

/// Set the user data for a body
void b2Body_SetUserData(b2BodyId bodyId, void* userData);

/// Get the user data stored in a body
void* b2Body_GetUserData(b2BodyId bodyId);

/// Get the world position of a body. This is the location of the body origin.
b2Pos b2Body_GetPosition(b2BodyId bodyId);

/// Get the world rotation of a body as a cosine/sine pair (complex number)
b2Rot b2Body_GetRotation(b2BodyId bodyId);

/// Get the world transform of a body.
b2WorldTransform b2Body_GetTransform(b2BodyId bodyId);

/// Set the world transform of a body. This acts as a teleport and is fairly expensive.
/// @note Generally you should create a body with then intended transform.
/// @see b2BodyDef::position and b2BodyDef::rotation
void b2Body_SetTransform(b2BodyId bodyId, b2Pos position, b2Rot rotation);

/// Get a local point on a body given a world point
b2Vec2 b2Body_GetLocalPoint(b2BodyId bodyId, b2Pos worldPoint);

/// Get a world point on a body given a local point
b2Pos b2Body_GetWorldPoint(b2BodyId bodyId, b2Vec2 localPoint);

/// Get a local vector on a body given a world vector
b2Vec2 b2Body_GetLocalVector(b2BodyId bodyId, b2Vec2 worldVector);

/// Get a world vector on a body given a local vector
b2Vec2 b2Body_GetWorldVector(b2BodyId bodyId, b2Vec2 localVector);

/// Get the linear velocity of a body's center of mass. Usually in meters per second.
b2Vec2 b2Body_GetLinearVelocity(b2BodyId bodyId);

/// Get the angular velocity of a body in radians per second
float b2Body_GetAngularVelocity(b2BodyId bodyId);

/// Set the linear velocity of a body. Usually in meters per second.
void b2Body_SetLinearVelocity(b2BodyId bodyId, b2Vec2 linearVelocity);

/// Set the angular velocity of a body in radians per second
void b2Body_SetAngularVelocity(b2BodyId bodyId, float angularVelocity);

/// Set the velocity to reach the given transform after a given time step.
/// The result will be close but maybe not exact. This is meant for kinematic bodies.
/// The target is not applied if the velocity would be below the sleep threshold and
/// the body is currently asleep.
/// @param bodyId The body id
/// @param target The target transform for the body
/// @param timeStep The time step of the next call to b2World_Step
/// @param wake Option to wake the body or not
void b2Body_SetTargetTransform(b2BodyId bodyId, b2WorldTransform target, float timeStep, bool wake);

/// Get the linear velocity of a local point attached to a body. Usually in meters per second.
b2Vec2 b2Body_GetLocalPointVelocity(b2BodyId bodyId, b2Vec2 localPoint);

/// Get the linear velocity of a world point attached to a body. Usually in meters per second.
b2Vec2 b2Body_GetWorldPointVelocity(b2BodyId bodyId, b2Pos worldPoint);

/// Apply a force at a world point. If the force is not applied at the center of mass,
/// it will generate a torque and affect the angular velocity. This optionally wakes up the body.
/// The force is ignored if the body is not awake.
/// @param bodyId The body id
/// @param force The world force vector, usually in newtons (N)
/// @param point The world position of the point of application
/// @param wake Option to wake up the body
void b2Body_ApplyForce(b2BodyId bodyId, b2Vec2 force, b2Pos point, bool wake);

/// Apply a force to the center of mass. This optionally wakes up the body.
/// The force is ignored if the body is not awake.
/// @param bodyId The body id
/// @param force the world force vector, usually in newtons (N).
/// @param wake also wake up the body
void b2Body_ApplyForceToCenter(b2BodyId bodyId, b2Vec2 force, bool wake);

/// Apply a torque. This affects the angular velocity without affecting the linear velocity.
/// This optionally wakes the body. The torque is ignored if the body is not awake.
/// @param bodyId The body id
/// @param torque about the z-axis (out of the screen), usually in N*m.
/// @param wake also wake up the body
void b2Body_ApplyTorque(b2BodyId bodyId, float torque, bool wake);

/// Clear the force and torque on this body. Forces and torques are automatically cleared after each world
/// step. So this only needs to be called if the application wants to remove the effect of previous
/// calls to apply forces and torques before the world step is called.
/// @param bodyId The body id
void b2Body_ClearForces(b2BodyId bodyId);

/// Apply an impulse at a point. This immediately modifies the velocity.
/// It also modifies the angular velocity if the point of application
/// is not at the center of mass. This optionally wakes the body.
/// The impulse is ignored if the body is not awake.
/// @param bodyId The body id
/// @param impulse the world impulse vector, usually in N*s or kg*m/s.
/// @param point the world position of the point of application.
/// @param wake also wake up the body
/// @warning This should be used for one-shot impulses. If you need a steady force,
/// use a force instead, which will work better with the sub-stepping solver.
void b2Body_ApplyLinearImpulse(b2BodyId bodyId, b2Vec2 impulse, b2Pos point, bool wake);

/// Apply an impulse to the center of mass. This immediately modifies the velocity.
/// The impulse is ignored if the body is not awake. This optionally wakes the body.
/// @param bodyId The body id
/// @param impulse the world impulse vector, usually in N*s or kg*m/s.
/// @param wake also wake up the body
/// @warning This should be used for one-shot impulses. If you need a steady force,
/// use a force instead, which will work better with the sub-stepping solver.
void b2Body_ApplyLinearImpulseToCenter(b2BodyId bodyId, b2Vec2 impulse, bool wake);

/// Apply an angular impulse. The impulse is ignored if the body is not awake.
/// This optionally wakes the body.
/// @param bodyId The body id
/// @param impulse the angular impulse, usually in units of kg*m*m/s
/// @param wake also wake up the body
/// @warning This should be used for one-shot impulses. If you need a steady torque,
/// use a torque instead, which will work better with the sub-stepping solver.
void b2Body_ApplyAngularImpulse(b2BodyId bodyId, float impulse, bool wake);

/// Get the mass of the body, usually in kilograms
float b2Body_GetMass(b2BodyId bodyId);

/// Get the rotational inertia of the body, usually in kg*m^2
float b2Body_GetRotationalInertia(b2BodyId bodyId);

/// Get the center of mass position of the body in local space.
b2Vec2 b2Body_GetLocalCenter(b2BodyId bodyId);

/// Get the center of mass position of the body in world space.
b2Pos b2Body_GetWorldCenter(b2BodyId bodyId);

/// Override the body's mass properties. Normally this is computed automatically using the
/// shape geometry and density. This information is lost if a shape is added or removed or if the
/// body type changes.
void b2Body_SetMassData(b2BodyId bodyId, b2MassData massData);

/// Get the mass data for a body
b2MassData b2Body_GetMassData(b2BodyId bodyId);

/// This updates the mass properties to the sum of the mass properties of the shapes.
/// This normally does not need to be called unless you called SetMassData to override
/// the mass and you later want to reset the mass.
/// You may also use this when automatic mass computation has been disabled.
/// You should call this regardless of body type.
/// Note that sensor shapes may have mass.
void b2Body_ApplyMassFromShapes(b2BodyId bodyId);

/// Adjust the linear damping. Normally this is set in b2BodyDef before creation.
void b2Body_SetLinearDamping(b2BodyId bodyId, float linearDamping);

/// Get the current linear damping.
float b2Body_GetLinearDamping(b2BodyId bodyId);

/// Adjust the angular damping. Normally this is set in b2BodyDef before creation.
void b2Body_SetAngularDamping(b2BodyId bodyId, float angularDamping);

/// Get the current angular damping.
float b2Body_GetAngularDamping(b2BodyId bodyId);

/// Adjust the gravity scale. Normally this is set in b2BodyDef before creation.
/// @see b2BodyDef::gravityScale
void b2Body_SetGravityScale(b2BodyId bodyId, float gravityScale);

/// Get the current gravity scale
float b2Body_GetGravityScale(b2BodyId bodyId);

/// @return true if this body is awake
bool b2Body_IsAwake(b2BodyId bodyId);

/// Wake a body from sleep. This wakes the entire island the body is touching.
/// @warning Putting a body to sleep will put the entire island of bodies touching this body to sleep,
/// which can be expensive and possibly unintuitive.
void b2Body_SetAwake(b2BodyId bodyId, bool awake);

/// Wake bodies touching this body. Works for static bodies.
void b2Body_WakeTouching(b2BodyId bodyId);

/// Enable or disable sleeping for this body. If sleeping is disabled the body will wake (and the entire island).
void b2Body_EnableSleep(b2BodyId bodyId, bool enableSleep);

/// Returns true if sleeping is enabled for this body
bool b2Body_IsSleepEnabled(b2BodyId bodyId);

/// Set the sleep threshold, usually in meters per second
void b2Body_SetSleepThreshold(b2BodyId bodyId, float sleepThreshold);

/// Get the sleep threshold, usually in meters per second.
float b2Body_GetSleepThreshold(b2BodyId bodyId);

/// Returns true if this body is enabled
bool b2Body_IsEnabled(b2BodyId bodyId);

/// Disable a body by removing it completely from the simulation. This is expensive.
void b2Body_Disable(b2BodyId bodyId);

/// Enable a body by adding it to the simulation. This is expensive.
void b2Body_Enable(b2BodyId bodyId);

/// Set the motion locks on this body.
void b2Body_SetMotionLocks(b2BodyId bodyId, b2MotionLocks locks);

/// Get the motion locks for this body.
b2MotionLocks b2Body_GetMotionLocks(b2BodyId bodyId);

/// Set this body to be a bullet. A bullet does continuous collision detection
/// against dynamic bodies (but not other bullets).
void b2Body_SetBullet(b2BodyId bodyId, bool flag);

/// Is this body a bullet?
bool b2Body_IsBullet(b2BodyId bodyId);

/// Enable or disable contact recycling for this body. Contact recycling is a performance optimization
/// that reuses contact manifolds when bodies move slightly. Disabling it can avoid ghost collisions
/// on characters at the cost of higher per-step work. Existing contacts retain their prior setting;
/// only contacts created after this call see the new value.
/// @see b2BodyDef::enableContactRecycling
void b2Body_EnableContactRecycling(b2BodyId bodyId, bool flag);

/// Is contact recycling enabled on this body?
bool b2Body_IsContactRecyclingEnabled(b2BodyId bodyId);

/// Enable/disable contact events on all shapes.
/// @see b2ShapeDef::enableContactEvents
/// @warning changing this at runtime may cause mismatched begin/end touch events
void b2Body_EnableContactEvents(b2BodyId bodyId, bool flag);

/// Enable/disable hit events on all shapes
/// @see b2ShapeDef::enableHitEvents
void b2Body_EnableHitEvents(b2BodyId bodyId, bool flag);

/// Get the world that owns this body
b2WorldId b2Body_GetWorld(b2BodyId bodyId);

/// Get the number of shapes on this body
int b2Body_GetShapeCount(b2BodyId bodyId);

/// Get the shape ids for all shapes on this body, up to the provided capacity.
/// @returns the number of shape ids stored in the user array
int b2Body_GetShapes(b2BodyId bodyId, b2ShapeId* shapeArray, int capacity);

/// Get the number of joints on this body
int b2Body_GetJointCount(b2BodyId bodyId);

/// Get the joint ids for all joints on this body, up to the provided capacity
/// @returns the number of joint ids stored in the user array
int b2Body_GetJoints(b2BodyId bodyId, b2JointId* jointArray, int capacity);

/// Get the maximum capacity required for retrieving all the touching contacts on a body
int b2Body_GetContactCapacity(b2BodyId bodyId);

/// Get the touching contact data for a body.
/// @note Box2D uses speculative collision so some contact points may be separated.
/// @returns the number of elements filled in the provided array
/// @warning do not ignore the return value, it specifies the valid number of elements
int b2Body_GetContactData(b2BodyId bodyId, b2ContactData* contactData, int capacity);

/// Get the current world AABB that contains all the attached shapes. Note that this may not encompass the body origin.
/// If there are no shapes attached then the returned AABB is empty and centered on the body origin.
b2AABB b2Body_ComputeAABB(b2BodyId bodyId);

/// Create a circle shape and attach it to a body. The shape definition and geometry are fully cloned.
/// Contacts are not created until the next time step.
/// @return the shape id for accessing the shape
b2ShapeId b2CreateCircleShape(b2BodyId bodyId, const(b2ShapeDef)* def, const(b2Circle)* circle);

/// Create a line segment shape and attach it to a body. The shape definition and geometry are fully cloned.
/// Contacts are not created until the next time step.
/// @return the shape id or b2_nullShapeId if the segment is too short.
b2ShapeId b2CreateSegmentShape(b2BodyId bodyId, const(b2ShapeDef)* def, const(b2Segment)* segment);

/// Create an orphaned chain segment shape and attach it to a body. The shape definition and
/// geometry are fully cloned. The caller is responsible for the segment's ghost vertices and
/// lifetime. The segment is not owned by any b2ChainShape (b2Shape_GetParentChain returns
/// b2_nullChainId). Contacts are not created until the next time step.
/// @return the shape id, or b2_nullShapeId if the segment is too short.
b2ShapeId b2CreateChainSegmentShape(b2BodyId bodyId, const(b2ShapeDef)* def, const(b2ChainSegment)* chainSegment);

/// Create a capsule shape and attach it to a body. The shape definition and geometry are fully cloned.
/// Contacts are not created until the next time step.
/// @return the shape id for accessing the shape, this will be b2_nullShapeId if the length is too small.
b2ShapeId b2CreateCapsuleShape(b2BodyId bodyId, const(b2ShapeDef)* def, const(b2Capsule)* capsule);

/// Create a polygon shape and attach it to a body. The shape definition and geometry are fully cloned.
/// Contacts are not created until the next time step.
/// @return the shape id for accessing the shape
b2ShapeId b2CreatePolygonShape(b2BodyId bodyId, const(b2ShapeDef)* def, const(b2Polygon)* polygon);

/// Destroy a shape. You may defer the body mass update which can improve performance if several shapes on a
///	body are destroyed at once.
///	@see b2Body_ApplyMassFromShapes
void b2DestroyShape(b2ShapeId shapeId, bool updateBodyMass);

/// Shape identifier validation. Provides validation for up to 64K allocations.
bool b2Shape_IsValid(b2ShapeId id);

/// Get the type of a shape
b2ShapeType b2Shape_GetType(b2ShapeId shapeId);

/// Get the id of the body that a shape is attached to
b2BodyId b2Shape_GetBody(b2ShapeId shapeId);

/// Get the world that owns this shape
b2WorldId b2Shape_GetWorld(b2ShapeId shapeId);

/// Returns true if the shape is a sensor. It is not possible to change a shape
/// from sensor to solid dynamically because this breaks the contract for
/// sensor events.
bool b2Shape_IsSensor(b2ShapeId shapeId);

/// Set the user data for a shape
void b2Shape_SetUserData(b2ShapeId shapeId, void* userData);

/// Get the user data for a shape. This is useful when you get a shape id
/// from an event or query.
void* b2Shape_GetUserData(b2ShapeId shapeId);

/// Set the mass density of a shape, usually in kg/m^2.
/// This will optionally update the mass properties on the parent body.
/// @see b2ShapeDef::density, b2Body_ApplyMassFromShapes
void b2Shape_SetDensity(b2ShapeId shapeId, float density, bool updateBodyMass);

/// Get the density of a shape, usually in kg/m^2
float b2Shape_GetDensity(b2ShapeId shapeId);

/// Set the friction on a shape
void b2Shape_SetFriction(b2ShapeId shapeId, float friction);

/// Get the friction of a shape
float b2Shape_GetFriction(b2ShapeId shapeId);

/// Set the shape restitution (bounciness)
void b2Shape_SetRestitution(b2ShapeId shapeId, float restitution);

/// Get the shape restitution
float b2Shape_GetRestitution(b2ShapeId shapeId);

/// Set the user material identifier
void b2Shape_SetUserMaterial(b2ShapeId shapeId, ulong material);

/// Get the user material identifier
ulong b2Shape_GetUserMaterial(b2ShapeId shapeId);

/// Set the shape surface material
void b2Shape_SetSurfaceMaterial(b2ShapeId shapeId, const(b2SurfaceMaterial)* surfaceMaterial);

/// Get the shape surface material
b2SurfaceMaterial b2Shape_GetSurfaceMaterial(b2ShapeId shapeId);

/// Get the shape filter
b2Filter b2Shape_GetFilter(b2ShapeId shapeId);

/// Set the current filter. This is almost as expensive as recreating the shape. This may cause
/// contacts to be immediately destroyed. However contacts are not created until the next world step.
/// Sensor overlap state is also not updated until the next world step.
/// @see b2ShapeDef::filter
void b2Shape_SetFilter(b2ShapeId shapeId, b2Filter filter);

/// Enable sensor events for this shape.
/// @see b2ShapeDef::enableSensorEvents
void b2Shape_EnableSensorEvents(b2ShapeId shapeId, bool flag);

/// Returns true if sensor events are enabled.
bool b2Shape_AreSensorEventsEnabled(b2ShapeId shapeId);

/// Enable contact events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
/// @see b2ShapeDef::enableContactEvents
/// @warning changing this at run-time may lead to lost begin/end events
void b2Shape_EnableContactEvents(b2ShapeId shapeId, bool flag);

/// Returns true if contact events are enabled
bool b2Shape_AreContactEventsEnabled(b2ShapeId shapeId);

/// Enable pre-solve contact events for this shape. Only applies to dynamic bodies. These are expensive
/// and must be carefully handled due to multithreading. Ignored for sensors.
/// @see b2PreSolveFcn
void b2Shape_EnablePreSolveEvents(b2ShapeId shapeId, bool flag);

/// Returns true if pre-solve events are enabled
bool b2Shape_ArePreSolveEventsEnabled(b2ShapeId shapeId);

/// Enable contact hit events for this shape. Ignored for sensors.
/// @see b2WorldDef.hitEventThreshold
void b2Shape_EnableHitEvents(b2ShapeId shapeId, bool flag);

/// Returns true if hit events are enabled
bool b2Shape_AreHitEventsEnabled(b2ShapeId shapeId);

/// Test a world point for overlap with a shape
bool b2Shape_TestPoint(b2ShapeId shapeId, b2Pos point);

/// Ray cast a single shape. The ray starts at the origin and extends by the translation. The output
/// point is a world position.
b2WorldCastOutput b2Shape_RayCast(b2ShapeId shapeId, b2Pos origin, b2Vec2 translation);

/// Get a copy of the shape's circle. Asserts the type is correct.
b2Circle b2Shape_GetCircle(b2ShapeId shapeId);

/// Get a copy of the shape's line segment. Asserts the type is correct.
b2Segment b2Shape_GetSegment(b2ShapeId shapeId);

/// Get a copy of the shape's chain segment. These come from chain shapes.
/// Asserts the type is correct.
b2ChainSegment b2Shape_GetChainSegment(b2ShapeId shapeId);

/// Get a copy of the shape's capsule. Asserts the type is correct.
b2Capsule b2Shape_GetCapsule(b2ShapeId shapeId);

/// Get a copy of the shape's convex polygon. Asserts the type is correct.
b2Polygon b2Shape_GetPolygon(b2ShapeId shapeId);

/// Allows you to change a shape to be a circle or update the current circle.
/// This does not modify the mass properties.
/// @see b2Body_ApplyMassFromShapes
void b2Shape_SetCircle(b2ShapeId shapeId, const(b2Circle)* circle);

/// Allows you to change a shape to be a capsule or update the current capsule.
/// This does not modify the mass properties.
/// @see b2Body_ApplyMassFromShapes
void b2Shape_SetCapsule(b2ShapeId shapeId, const(b2Capsule)* capsule);

/// Allows you to change a shape to be a segment or update the current segment.
void b2Shape_SetSegment(b2ShapeId shapeId, const(b2Segment)* segment);

/// Allows you to change a shape to be a polygon or update the current polygon.
/// This does not modify the mass properties.
/// @see b2Body_ApplyMassFromShapes
void b2Shape_SetPolygon(b2ShapeId shapeId, const(b2Polygon)* polygon);

/// Allows you to change a shape to be an orphaned chain segment or update the current chain
/// segment, including its ghost vertices. The chainId on the input is ignored. The resulting
/// shape is always orphaned. Asserts if the shape is already a chain segment
/// owned by a b2ChainShape (chainId != B2_NULL_INDEX).
void b2Shape_SetChainSegment(b2ShapeId shapeId, const(b2ChainSegment)* chainSegment);

/// Get the parent chain id if the shape type is a chain segment, otherwise
/// returns b2_nullChainId.
b2ChainId b2Shape_GetParentChain(b2ShapeId shapeId);

/// Get the maximum capacity required for retrieving all the touching contacts on a shape
int b2Shape_GetContactCapacity(b2ShapeId shapeId);

/// Get the touching contact data for a shape. The provided shapeId will be either shapeIdA or shapeIdB on the contact data.
/// @note Box2D uses speculative collision so some contact points may be separated.
/// @returns the number of elements filled in the provided array
/// @warning do not ignore the return value, it specifies the valid number of elements
int b2Shape_GetContactData(b2ShapeId shapeId, b2ContactData* contactData, int capacity);

/// Get the maximum capacity required for retrieving all the overlapped shapes on a sensor shape.
/// This returns 0 if the provided shape is not a sensor.
/// @param shapeId the id of a sensor shape
/// @returns the required capacity to get all the overlaps in b2Shape_GetSensorData
int b2Shape_GetSensorCapacity(b2ShapeId shapeId);

/// Get the overlap data for a sensor shape computed the previous world step.
/// @param shapeId the id of a sensor shape
/// @param visitorIds a user allocated array that is filled with the overlapping shapes (visitors)
/// @param capacity the capacity of overlappedShapes
/// @returns the number of elements filled in the provided array
/// @warning do not ignore the return value, it specifies the valid number of elements
/// @warning overlaps may contain destroyed shapes so use b2Shape_IsValid to confirm each overlap
int b2Shape_GetSensorData(b2ShapeId shapeId, b2ShapeId* visitorIds, int capacity);

/// Get the current world AABB
b2AABB b2Shape_GetAABB(b2ShapeId shapeId);

/// Compute the mass data for a shape
b2MassData b2Shape_ComputeMassData(b2ShapeId shapeId);

/// Get the closest point on a shape to a target point. Target and result are world positions.
/// todo need sample
b2Pos b2Shape_GetClosestPoint(b2ShapeId shapeId, b2Pos target);

/// Apply a wind force to the body for this shape using the density of air. This considers
/// the projected area of the shape in the wind direction. This also considers
/// the relative velocity of the shape.
/// @param shapeId the shape id
/// @param wind the wind velocity in world space
/// @param drag the drag coefficient, the force that opposes the relative velocity
/// @param lift the lift coefficient, the force that is perpendicular to the relative velocity
/// @param wake should this wake the body
void b2Shape_ApplyWind(b2ShapeId shapeId, b2Vec2 wind, float drag, float lift, bool wake);

/// Create a chain shape
/// @see b2ChainDef for details
b2ChainId b2CreateChain(b2BodyId bodyId, const(b2ChainDef)* def);

/// Destroy a chain shape
void b2DestroyChain(b2ChainId chainId);

/// Get the world that owns this chain shape
b2WorldId b2Chain_GetWorld(b2ChainId chainId);

/// Get the number of segments on this chain
int b2Chain_GetSegmentCount(b2ChainId chainId);

/// Fill a user array with chain segment shape ids up to the specified capacity. Returns
/// the actual number of segments returned.
int b2Chain_GetSegments(b2ChainId chainId, b2ShapeId* segmentArray, int capacity);

/// Get the number of materials used on this chain. Must be 1 or the number of segments.
int b2Chain_GetSurfaceMaterialCount(b2ChainId chainId);

/// Set a chain material. If the chain has only one material, this material is applied to all
/// segments. Otherwise it is applied to a single segment.
void b2Chain_SetSurfaceMaterial(b2ChainId chainId, const(b2SurfaceMaterial)* material, int materialIndex);

/// Get a chain material by index.
b2SurfaceMaterial b2Chain_GetSurfaceMaterial(b2ChainId chainId, int materialIndex);

/// Chain identifier validation. Provides validation for up to 64K allocations.
bool b2Chain_IsValid(b2ChainId id);

/// Destroy a joint. Optionally wake attached bodies.
void b2DestroyJoint(b2JointId jointId, bool wakeAttached);

/// Joint identifier validation. Provides validation for up to 64K allocations.
bool b2Joint_IsValid(b2JointId id);

/// Get the joint type
b2JointType b2Joint_GetType(b2JointId jointId);

/// Get body A id on a joint
b2BodyId b2Joint_GetBodyA(b2JointId jointId);

/// Get body B id on a joint
b2BodyId b2Joint_GetBodyB(b2JointId jointId);

/// Get the world that owns this joint
b2WorldId b2Joint_GetWorld(b2JointId jointId);

/// Set the local frame on bodyA
void b2Joint_SetLocalFrameA(b2JointId jointId, b2Transform localFrame);

/// Get the local frame on bodyA
b2Transform b2Joint_GetLocalFrameA(b2JointId jointId);

/// Set the local frame on bodyB
void b2Joint_SetLocalFrameB(b2JointId jointId, b2Transform localFrame);

/// Get the local frame on bodyB
b2Transform b2Joint_GetLocalFrameB(b2JointId jointId);

/// Toggle collision between connected bodies
void b2Joint_SetCollideConnected(b2JointId jointId, bool shouldCollide);

/// Is collision allowed between connected bodies?
bool b2Joint_GetCollideConnected(b2JointId jointId);

/// Set the user data on a joint
void b2Joint_SetUserData(b2JointId jointId, void* userData);

/// Get the user data on a joint
void* b2Joint_GetUserData(b2JointId jointId);

/// Wake the bodies connect to this joint
void b2Joint_WakeBodies(b2JointId jointId);

/// Get the current constraint force for this joint. Usually in Newtons.
b2Vec2 b2Joint_GetConstraintForce(b2JointId jointId);

/// Get the current constraint torque for this joint. Usually in Newton * meters.
float b2Joint_GetConstraintTorque(b2JointId jointId);

/// Get the current linear separation error for this joint. Does not consider admissible movement. Usually in meters.
float b2Joint_GetLinearSeparation(b2JointId jointId);

/// Get the current angular separation error for this joint. Does not consider admissible movement. Usually in meters.
float b2Joint_GetAngularSeparation(b2JointId jointId);

/// Set the joint constraint tuning. Advanced feature.
/// @param jointId the joint
/// @param hertz the stiffness in Hertz (cycles per second)
/// @param dampingRatio the non-dimensional damping ratio (one for critical damping)
void b2Joint_SetConstraintTuning(b2JointId jointId, float hertz, float dampingRatio);

/// Get the joint constraint tuning. Advanced feature.
void b2Joint_GetConstraintTuning(b2JointId jointId, float* hertz, float* dampingRatio);

/// Set the force threshold for joint events (Newtons)
void b2Joint_SetForceThreshold(b2JointId jointId, float threshold);

/// Get the force threshold for joint events (Newtons)
float b2Joint_GetForceThreshold(b2JointId jointId);

/// Set the torque threshold for joint events (N-m)
void b2Joint_SetTorqueThreshold(b2JointId jointId, float threshold);

/// Get the torque threshold for joint events (N-m)
float b2Joint_GetTorqueThreshold(b2JointId jointId);

/// Create a distance joint
/// @see b2DistanceJointDef for details
b2JointId b2CreateDistanceJoint(b2WorldId worldId, const(b2DistanceJointDef)* def);

/// Set the rest length of a distance joint
/// @param jointId The id for a distance joint
/// @param length The new distance joint length
void b2DistanceJoint_SetLength(b2JointId jointId, float length);

/// Get the rest length of a distance joint
float b2DistanceJoint_GetLength(b2JointId jointId);

/// Enable/disable the distance joint spring. When disabled the distance joint is rigid.
void b2DistanceJoint_EnableSpring(b2JointId jointId, bool enableSpring);

/// Is the distance joint spring enabled?
bool b2DistanceJoint_IsSpringEnabled(b2JointId jointId);

/// Set the force range for the spring.
void b2DistanceJoint_SetSpringForceRange(b2JointId jointId, float lowerForce, float upperForce);

/// Get the force range for the spring.
void b2DistanceJoint_GetSpringForceRange(b2JointId jointId, float* lowerForce, float* upperForce);

/// Set the spring stiffness in Hertz
void b2DistanceJoint_SetSpringHertz(b2JointId jointId, float hertz);

/// Set the spring damping ratio, non-dimensional
void b2DistanceJoint_SetSpringDampingRatio(b2JointId jointId, float dampingRatio);

/// Get the spring Hertz
float b2DistanceJoint_GetSpringHertz(b2JointId jointId);

/// Get the spring damping ratio
float b2DistanceJoint_GetSpringDampingRatio(b2JointId jointId);

/// Enable joint limit. The limit only works if the joint spring is enabled. Otherwise the joint is rigid
/// and the limit has no effect.
void b2DistanceJoint_EnableLimit(b2JointId jointId, bool enableLimit);

/// Is the distance joint limit enabled?
bool b2DistanceJoint_IsLimitEnabled(b2JointId jointId);

/// Set the minimum and maximum length parameters of a distance joint
void b2DistanceJoint_SetLengthRange(b2JointId jointId, float minLength, float maxLength);

/// Get the distance joint minimum length
float b2DistanceJoint_GetMinLength(b2JointId jointId);

/// Get the distance joint maximum length
float b2DistanceJoint_GetMaxLength(b2JointId jointId);

/// Get the current length of a distance joint
float b2DistanceJoint_GetCurrentLength(b2JointId jointId);

/// Enable/disable the distance joint motor
void b2DistanceJoint_EnableMotor(b2JointId jointId, bool enableMotor);

/// Is the distance joint motor enabled?
bool b2DistanceJoint_IsMotorEnabled(b2JointId jointId);

/// Set the distance joint motor speed, usually in meters per second
void b2DistanceJoint_SetMotorSpeed(b2JointId jointId, float motorSpeed);

/// Get the distance joint motor speed, usually in meters per second
float b2DistanceJoint_GetMotorSpeed(b2JointId jointId);

/// Set the distance joint maximum motor force, usually in newtons
void b2DistanceJoint_SetMaxMotorForce(b2JointId jointId, float force);

/// Get the distance joint maximum motor force, usually in newtons
float b2DistanceJoint_GetMaxMotorForce(b2JointId jointId);

/// Get the distance joint current motor force, usually in newtons
float b2DistanceJoint_GetMotorForce(b2JointId jointId);

/// Create a motor joint
/// @see b2MotorJointDef for details
b2JointId b2CreateMotorJoint(b2WorldId worldId, const(b2MotorJointDef)* def);

/// Set the desired relative linear velocity in meters per second
void b2MotorJoint_SetLinearVelocity(b2JointId jointId, b2Vec2 velocity);

/// Get the desired relative linear velocity in meters per second
b2Vec2 b2MotorJoint_GetLinearVelocity(b2JointId jointId);

/// Set the desired relative angular velocity in radians per second
void b2MotorJoint_SetAngularVelocity(b2JointId jointId, float velocity);

/// Get the desired relative angular velocity in radians per second
float b2MotorJoint_GetAngularVelocity(b2JointId jointId);

/// Set the motor joint maximum force, usually in newtons
void b2MotorJoint_SetMaxVelocityForce(b2JointId jointId, float maxForce);

/// Get the motor joint maximum force, usually in newtons
float b2MotorJoint_GetMaxVelocityForce(b2JointId jointId);

/// Set the motor joint maximum torque, usually in newton-meters
void b2MotorJoint_SetMaxVelocityTorque(b2JointId jointId, float maxTorque);

/// Get the motor joint maximum torque, usually in newton-meters
float b2MotorJoint_GetMaxVelocityTorque(b2JointId jointId);

/// Set the spring linear hertz stiffness
void b2MotorJoint_SetLinearHertz(b2JointId jointId, float hertz);

/// Get the spring linear hertz stiffness
float b2MotorJoint_GetLinearHertz(b2JointId jointId);

/// Set the spring linear damping ratio. Use 1.0 for critical damping.
void b2MotorJoint_SetLinearDampingRatio(b2JointId jointId, float damping);

/// Get the spring linear damping ratio.
float b2MotorJoint_GetLinearDampingRatio(b2JointId jointId);

/// Set the spring angular hertz stiffness
void b2MotorJoint_SetAngularHertz(b2JointId jointId, float hertz);

/// Get the spring angular hertz stiffness
float b2MotorJoint_GetAngularHertz(b2JointId jointId);

/// Set the spring angular damping ratio. Use 1.0 for critical damping.
void b2MotorJoint_SetAngularDampingRatio(b2JointId jointId, float damping);

/// Get the spring angular damping ratio.
float b2MotorJoint_GetAngularDampingRatio(b2JointId jointId);

/// Set the maximum spring force in newtons.
void b2MotorJoint_SetMaxSpringForce(b2JointId jointId, float maxForce);

/// Get the maximum spring force in newtons.
float b2MotorJoint_GetMaxSpringForce(b2JointId jointId);

/// Set the maximum spring torque in newtons * meters
void b2MotorJoint_SetMaxSpringTorque(b2JointId jointId, float maxTorque);

/// Get the maximum spring torque in newtons * meters
float b2MotorJoint_GetMaxSpringTorque(b2JointId jointId);

/// Create a filter joint.
/// @see b2FilterJointDef for details
b2JointId b2CreateFilterJoint(b2WorldId worldId, const(b2FilterJointDef)* def);

/// Create a prismatic (slider) joint.
/// @see b2PrismaticJointDef for details
b2JointId b2CreatePrismaticJoint(b2WorldId worldId, const(b2PrismaticJointDef)* def);

/// Enable/disable the joint spring.
void b2PrismaticJoint_EnableSpring(b2JointId jointId, bool enableSpring);

/// Is the prismatic joint spring enabled or not?
bool b2PrismaticJoint_IsSpringEnabled(b2JointId jointId);

/// Set the prismatic joint stiffness in Hertz.
/// This should usually be less than a quarter of the simulation rate. For example, if the simulation
/// runs at 60Hz then the joint stiffness should be 15Hz or less.
void b2PrismaticJoint_SetSpringHertz(b2JointId jointId, float hertz);

/// Get the prismatic joint stiffness in Hertz
float b2PrismaticJoint_GetSpringHertz(b2JointId jointId);

/// Set the prismatic joint damping ratio (non-dimensional)
void b2PrismaticJoint_SetSpringDampingRatio(b2JointId jointId, float dampingRatio);

/// Get the prismatic spring damping ratio (non-dimensional)
float b2PrismaticJoint_GetSpringDampingRatio(b2JointId jointId);

/// Set the prismatic joint spring target angle, usually in meters
void b2PrismaticJoint_SetTargetTranslation(b2JointId jointId, float translation);

/// Get the prismatic joint spring target translation, usually in meters
float b2PrismaticJoint_GetTargetTranslation(b2JointId jointId);

/// Enable/disable a prismatic joint limit
void b2PrismaticJoint_EnableLimit(b2JointId jointId, bool enableLimit);

/// Is the prismatic joint limit enabled?
bool b2PrismaticJoint_IsLimitEnabled(b2JointId jointId);

/// Get the prismatic joint lower limit
float b2PrismaticJoint_GetLowerLimit(b2JointId jointId);

/// Get the prismatic joint upper limit
float b2PrismaticJoint_GetUpperLimit(b2JointId jointId);

/// Set the prismatic joint limits
void b2PrismaticJoint_SetLimits(b2JointId jointId, float lower, float upper);

/// Enable/disable a prismatic joint motor
void b2PrismaticJoint_EnableMotor(b2JointId jointId, bool enableMotor);

/// Is the prismatic joint motor enabled?
bool b2PrismaticJoint_IsMotorEnabled(b2JointId jointId);

/// Set the prismatic joint motor speed, usually in meters per second
void b2PrismaticJoint_SetMotorSpeed(b2JointId jointId, float motorSpeed);

/// Get the prismatic joint motor speed, usually in meters per second
float b2PrismaticJoint_GetMotorSpeed(b2JointId jointId);

/// Set the prismatic joint maximum motor force, usually in newtons
void b2PrismaticJoint_SetMaxMotorForce(b2JointId jointId, float force);

/// Get the prismatic joint maximum motor force, usually in newtons
float b2PrismaticJoint_GetMaxMotorForce(b2JointId jointId);

/// Get the prismatic joint current motor force, usually in newtons
float b2PrismaticJoint_GetMotorForce(b2JointId jointId);

/// Get the current joint translation, usually in meters.
float b2PrismaticJoint_GetTranslation(b2JointId jointId);

/// Get the current joint translation speed, usually in meters per second.
float b2PrismaticJoint_GetSpeed(b2JointId jointId);

/// Create a revolute joint
/// @see b2RevoluteJointDef for details
b2JointId b2CreateRevoluteJoint(b2WorldId worldId, const(b2RevoluteJointDef)* def);

/// Enable/disable the revolute joint spring
void b2RevoluteJoint_EnableSpring(b2JointId jointId, bool enableSpring);

/// It the revolute angular spring enabled?
bool b2RevoluteJoint_IsSpringEnabled(b2JointId jointId);

/// Set the revolute joint spring stiffness in Hertz
void b2RevoluteJoint_SetSpringHertz(b2JointId jointId, float hertz);

/// Get the revolute joint spring stiffness in Hertz
float b2RevoluteJoint_GetSpringHertz(b2JointId jointId);

/// Set the revolute joint spring damping ratio, non-dimensional
void b2RevoluteJoint_SetSpringDampingRatio(b2JointId jointId, float dampingRatio);

/// Get the revolute joint spring damping ratio, non-dimensional
float b2RevoluteJoint_GetSpringDampingRatio(b2JointId jointId);

/// Set the revolute joint spring target angle, radians
void b2RevoluteJoint_SetTargetAngle(b2JointId jointId, float angle);

/// Get the revolute joint spring target angle, radians
float b2RevoluteJoint_GetTargetAngle(b2JointId jointId);

/// Get the revolute joint current angle in radians relative to the reference angle
/// @see b2RevoluteJointDef::referenceAngle
float b2RevoluteJoint_GetAngle(b2JointId jointId);

/// Enable/disable the revolute joint limit
void b2RevoluteJoint_EnableLimit(b2JointId jointId, bool enableLimit);

/// Is the revolute joint limit enabled?
bool b2RevoluteJoint_IsLimitEnabled(b2JointId jointId);

/// Get the revolute joint lower limit in radians
float b2RevoluteJoint_GetLowerLimit(b2JointId jointId);

/// Get the revolute joint upper limit in radians
float b2RevoluteJoint_GetUpperLimit(b2JointId jointId);

/// Set the revolute joint limits in radians. It is expected that lower <= upper
/// and that -0.99 * B2_PI <= lower && upper <= -0.99 * B2_PI.
void b2RevoluteJoint_SetLimits(b2JointId jointId, float lower, float upper);

/// Enable/disable a revolute joint motor
void b2RevoluteJoint_EnableMotor(b2JointId jointId, bool enableMotor);

/// Is the revolute joint motor enabled?
bool b2RevoluteJoint_IsMotorEnabled(b2JointId jointId);

/// Set the revolute joint motor speed in radians per second
void b2RevoluteJoint_SetMotorSpeed(b2JointId jointId, float motorSpeed);

/// Get the revolute joint motor speed in radians per second
float b2RevoluteJoint_GetMotorSpeed(b2JointId jointId);

/// Get the revolute joint current motor torque, usually in newton-meters
float b2RevoluteJoint_GetMotorTorque(b2JointId jointId);

/// Set the revolute joint maximum motor torque, usually in newton-meters
void b2RevoluteJoint_SetMaxMotorTorque(b2JointId jointId, float torque);

/// Get the revolute joint maximum motor torque, usually in newton-meters
float b2RevoluteJoint_GetMaxMotorTorque(b2JointId jointId);

/// Create a weld joint
/// @see b2WeldJointDef for details
b2JointId b2CreateWeldJoint(b2WorldId worldId, const(b2WeldJointDef)* def);

/// Set the weld joint linear stiffness in Hertz. 0 is rigid.
void b2WeldJoint_SetLinearHertz(b2JointId jointId, float hertz);

/// Get the weld joint linear stiffness in Hertz
float b2WeldJoint_GetLinearHertz(b2JointId jointId);

/// Set the weld joint linear damping ratio (non-dimensional)
void b2WeldJoint_SetLinearDampingRatio(b2JointId jointId, float dampingRatio);

/// Get the weld joint linear damping ratio (non-dimensional)
float b2WeldJoint_GetLinearDampingRatio(b2JointId jointId);

/// Set the weld joint angular stiffness in Hertz. 0 is rigid.
void b2WeldJoint_SetAngularHertz(b2JointId jointId, float hertz);

/// Get the weld joint angular stiffness in Hertz
float b2WeldJoint_GetAngularHertz(b2JointId jointId);

/// Set weld joint angular damping ratio, non-dimensional
void b2WeldJoint_SetAngularDampingRatio(b2JointId jointId, float dampingRatio);

/// Get the weld joint angular damping ratio, non-dimensional
float b2WeldJoint_GetAngularDampingRatio(b2JointId jointId);

/// Create a wheel joint
/// @see b2WheelJointDef for details
b2JointId b2CreateWheelJoint(b2WorldId worldId, const(b2WheelJointDef)* def);

/// Enable/disable the wheel joint spring
void b2WheelJoint_EnableSpring(b2JointId jointId, bool enableSpring);

/// Is the wheel joint spring enabled?
bool b2WheelJoint_IsSpringEnabled(b2JointId jointId);

/// Set the wheel joint stiffness in Hertz
void b2WheelJoint_SetSpringHertz(b2JointId jointId, float hertz);

/// Get the wheel joint stiffness in Hertz
float b2WheelJoint_GetSpringHertz(b2JointId jointId);

/// Set the wheel joint damping ratio, non-dimensional
void b2WheelJoint_SetSpringDampingRatio(b2JointId jointId, float dampingRatio);

/// Get the wheel joint damping ratio, non-dimensional
float b2WheelJoint_GetSpringDampingRatio(b2JointId jointId);

/// Enable/disable the wheel joint limit
void b2WheelJoint_EnableLimit(b2JointId jointId, bool enableLimit);

/// Is the wheel joint limit enabled?
bool b2WheelJoint_IsLimitEnabled(b2JointId jointId);

/// Get the wheel joint lower limit
float b2WheelJoint_GetLowerLimit(b2JointId jointId);

/// Get the wheel joint upper limit
float b2WheelJoint_GetUpperLimit(b2JointId jointId);

/// Set the wheel joint limits
void b2WheelJoint_SetLimits(b2JointId jointId, float lower, float upper);

/// Enable/disable the wheel joint motor
void b2WheelJoint_EnableMotor(b2JointId jointId, bool enableMotor);

/// Is the wheel joint motor enabled?
bool b2WheelJoint_IsMotorEnabled(b2JointId jointId);

/// Set the wheel joint motor speed in radians per second
void b2WheelJoint_SetMotorSpeed(b2JointId jointId, float motorSpeed);

/// Get the wheel joint motor speed in radians per second
float b2WheelJoint_GetMotorSpeed(b2JointId jointId);

/// Set the wheel joint maximum motor torque, usually in newton-meters
void b2WheelJoint_SetMaxMotorTorque(b2JointId jointId, float torque);

/// Get the wheel joint maximum motor torque, usually in newton-meters
float b2WheelJoint_GetMaxMotorTorque(b2JointId jointId);

/// Get the wheel joint current motor torque, usually in newton-meters
float b2WheelJoint_GetMotorTorque(b2JointId jointId);

/// Contact identifier validation. Provides validation for up to 2^32 allocations.
bool b2Contact_IsValid(b2ContactId id);

/// Get the data for a contact. The manifold may have no points if the contact is not touching.
b2ContactData b2Contact_GetData(b2ContactId contactId);

/// Replay a recording by re-running the engine and asserting recorded ids and state match.
/// @param data Recorded bytes, e.g. from b2Recording_GetData or a loaded file
/// @param size Number of recorded bytes
/// @param workerCount Worker count to use for replay. 0 uses the serial single-worker fallback.
/// @return true if replay completed without divergence, false on any mismatch
bool b2ValidateReplay(const(void)* data, int size, int workerCount);

/// Open a recording for incremental playback and replay up to the first step. The player copies
/// the bytes, so you may free or destroy the source buffer immediately after this call.
/// @param data Recorded bytes, e.g. from b2Recording_GetData or a loaded file
/// @param size Number of recorded bytes
/// @param workerCount Worker count for the replay world. 0 uses the serial single-worker fallback.
/// @return A player handle, or NULL if the recording is malformed
b2RecPlayer* b2RecPlayer_Create(const(void)* data, int size, int workerCount);

/// Advance the replay by one recorded step.
/// @return true if a step executed, false once the end of the recording is reached
bool b2RecPlayer_StepFrame(b2RecPlayer* player);

/// Get the id of the replayed world.
b2WorldId b2RecPlayer_GetWorldId(const(b2RecPlayer)* player);

/// Rewind the player to the first step, recreating the replay world from the file.
void b2RecPlayer_Restart(b2RecPlayer* player);

/// Seek to a recorded step. Seeking backward rewinds and re-runs from the start, so the
/// cost grows with the target frame. Clamps to the recording bounds.
void b2RecPlayer_SeekFrame(b2RecPlayer* player, int targetFrame);

/// Get the number of steps replayed so far.
int b2RecPlayer_GetFrame(const(b2RecPlayer)* player);

/// Get static metadata for the recording (frame count, recorded tuning, time).
b2RecPlayerInfo b2RecPlayer_GetInfo(const(b2RecPlayer)* player);

/// Returns true once the end of the recording has been reached.
bool b2RecPlayer_IsAtEnd(const(b2RecPlayer)* player);

/// Returns true if a recorded state hash failed to reproduce, meaning replay diverged.
bool b2RecPlayer_HasDiverged(const(b2RecPlayer)* player);

/// Get the first step at which replay diverged, or -1 if it has not diverged.
int b2RecPlayer_GetDivergeFrame(const(b2RecPlayer)* player);

/// Tune the keyframe ring used to speed up backward seeking. A keyframe is a periodic snapshot the
/// player restores from instead of replaying from the start, trading memory for seek speed.
/// @param player the recording player
/// @param budgetBytes Memory cap for the kept snapshots. The spacing widens to stay under it.
/// @param minIntervalFrames Finest spacing between keyframes, in frames.
/// A zero budget or a non-positive interval keeps that value. Clears the existing ring, so call
/// b2RecPlayer_Restart afterward to repopulate it under the new policy.
void b2RecPlayer_SetKeyframePolicy(b2RecPlayer* player, size_t budgetBytes, int minIntervalFrames);

/// Get the keyframe memory budget in bytes.
size_t b2RecPlayer_GetKeyframeBudget(const(b2RecPlayer)* player);

/// Get the finest keyframe spacing in frames.
int b2RecPlayer_GetKeyframeMinInterval(const(b2RecPlayer)* player);

/// Get the current keyframe spacing in frames. Starts at the min interval and doubles as the ring
/// evicts to stay under budget, so it reflects the effective backward-seek granularity right now.
int b2RecPlayer_GetKeyframeInterval(const(b2RecPlayer)* player);

/// Get the memory currently held by keyframe snapshots, in bytes.
size_t b2RecPlayer_GetKeyframeBytes(const(b2RecPlayer)* player);

/// Close a player and free its replay world and file buffer.
void b2RecPlayer_Destroy(b2RecPlayer* player);

/// Draw spatial queries recorded during the most recently replayed frame.
/// Call after b2World_Draw so queries are layered on top of the world.
/// @param player A valid player handle
/// @param draw Debug draw callbacks. NULL draw function pointers are skipped.
/// @param queryIndex Index into the frame's queries to draw, or -1 to draw all of them.
void b2RecPlayer_DrawFrameQueries(b2RecPlayer* player, b2DebugDraw* draw, int queryIndex);

/// Get the number of spatial queries recorded for the most recently replayed frame.
int b2RecPlayer_GetFrameQueryCount(const(b2RecPlayer)* player);

/// Get a recorded query from the most recently replayed frame by index.
b2RecQueryInfo b2RecPlayer_GetFrameQuery(const(b2RecPlayer)* player, int index);

/// Get one result of a recorded query from the most recently replayed frame.
b2RecQueryHit b2RecPlayer_GetFrameQueryHit(const(b2RecPlayer)* player, int queryIndex, int hitIndex);

/// Get the number of body slots tracked for the outliner. This is the creation-order span and
/// includes holes for destroyed bodies, so it only grows as the replay advances.
int b2RecPlayer_GetBodyCount(const(b2RecPlayer)* player);

/// Get a tracked body by creation ordinal. Returns b2_nullBodyId for a destroyed slot, an ordinal not
/// yet reached at the current frame, or an out-of-range index. Validate with b2Body_IsValid.
b2BodyId b2RecPlayer_GetBodyId(const(b2RecPlayer)* player, int index);

// ---------------------------------------------------------------------------
// Integration test (requires linking the Box2D library)
// ---------------------------------------------------------------------------

extern (D):

unittest
{
    // The library links and reports its version.
    const b2Version v = b2GetVersion();
    assert(v.major == 3);

    // A dynamic body falls under gravity.
    b2WorldDef wd = b2DefaultWorldDef();
    wd.gravity = b2Vec2(0.0f, -10.0f);
    b2WorldId world = b2CreateWorld(&wd);
    scope (exit)
        b2DestroyWorld(world);

    b2BodyDef bd = b2DefaultBodyDef();
    bd.type = b2BodyType.b2_dynamicBody;
    bd.position = b2Vec2(0.0f, 10.0f);
    b2BodyId falling = b2CreateBody(world, &bd);

    b2Polygon boxGeom = b2MakeBox(0.5f, 0.5f);
    b2ShapeDef sd = b2DefaultShapeDef();
    sd.density = 1.0f;
    b2CreatePolygonShape(falling, &sd, &boxGeom);

    immutable float startY = b2Body_GetPosition(falling).y;
    foreach (_; 0 .. 30)
        b2World_Step(world, 1.0f / 60.0f, 4);
    assert(b2Body_GetPosition(falling).y < startY);
}
