// SPDX-License-Identifier: MIT
// A minimal Box2D simulation: drop a dynamic box onto static ground and print
// its falling position each step. Mirrors the official Box2D "hello world".
import std.stdio;
import box2d;

void main()
{
    // Create a world with downward gravity.
    b2WorldDef worldDef = b2DefaultWorldDef();
    worldDef.gravity = b2Vec2(0.0f, -10.0f);
    b2WorldId world = b2CreateWorld(&worldDef);
    scope (exit)
        b2DestroyWorld(world);

    // Static ground body with a wide box shape.
    b2BodyDef groundDef = b2DefaultBodyDef();
    groundDef.position = b2Vec2(0.0f, -10.0f);
    b2BodyId ground = b2CreateBody(world, &groundDef);

    b2Polygon groundBox = b2MakeBox(50.0f, 10.0f);
    b2ShapeDef groundShape = b2DefaultShapeDef();
    b2CreatePolygonShape(ground, &groundShape, &groundBox);

    // Dynamic body that will fall under gravity.
    b2BodyDef bodyDef = b2DefaultBodyDef();
    bodyDef.type = b2BodyType.b2_dynamicBody;
    bodyDef.position = b2Vec2(0.0f, 8.0f);
    b2BodyId box = b2CreateBody(world, &bodyDef);

    b2Polygon dynamicBox = b2MakeBox(0.5f, 0.5f);
    b2ShapeDef shapeDef = b2DefaultShapeDef();
    shapeDef.density = 1.0f;
    shapeDef.material.friction = 0.3f;
    b2CreatePolygonShape(box, &shapeDef, &dynamicBox);

    b2Version v = b2GetVersion();
    writefln("Box2D %d.%d.%d", v.major, v.minor, v.revision);

    immutable float timeStep = 1.0f / 60.0f;
    immutable int subStepCount = 4;

    float startY = b2Body_GetPosition(box).y;
    foreach (i; 0 .. 90)
    {
        b2World_Step(world, timeStep, subStepCount);
        b2Vec2 p = b2Body_GetPosition(box);
        b2Rot rot = b2Body_GetRotation(box);
        if (i % 15 == 0 || i == 89)
            writefln("step %2d: x=%6.2f y=%6.2f angle=%5.2f", i, p.x, p.y, b2Rot_GetAngle(rot));
    }

    float endY = b2Body_GetPosition(box).y;
    assert(endY < startY, "box should have fallen");
    assert(endY > 0.0f, "box should be resting on the ground, not through it");
    writeln("OK: the box fell and came to rest on the ground.");
}
