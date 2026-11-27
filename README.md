# box2d.d

[![CI](https://github.com/poita/box2d.d/actions/workflows/ci.yml/badge.svg)](https://github.com/poita/box2d.d/actions/workflows/ci.yml)

Cross-platform [D](https://dlang.org) bindings for [Box2D](https://box2d.org)
3.x — Erin Catto's efficient 2D physics engine.

Box2D 3.x is written in C with a clean C API, which makes these bindings a thin,
`@nogc nothrow` translation of that API. The C source is vendored and built from
source, so the package is self-contained: no system Box2D install required.

- **box2d.d version:** 0.2.0
- **Box2D version:** 3.2.0 (vendored under `native/box2d`)
- **License:** MIT (both these bindings and Box2D itself)
- **Precision:** single precision (the default Box2D build)

## Installation

Add the dependency with dub:

```sh
dub add box2d
```

or in your `dub.json`:

```json
"dependencies": {
    "box2d": "~>0.2"
}
```

### Build requirements

The default `vendored` configuration compiles the bundled Box2D C source into a
static library the first time you build, and links it automatically. This needs:

- **CMake** (3.16+) on `PATH`
- A **C17 compiler** (clang, gcc, or MSVC)

These are only needed at build time. If you would rather link a Box2D library
that is already installed on your system, use the `system` configuration:

```json
"subConfigurations": {
    "box2d": "system"
}
```

## Usage

```d
import box2d;

void main()
{
    b2WorldDef worldDef = b2DefaultWorldDef();
    worldDef.gravity = b2Vec2(0.0f, -10.0f);
    b2WorldId world = b2CreateWorld(&worldDef);
    scope (exit) b2DestroyWorld(world);

    // Static ground.
    b2BodyDef groundDef = b2DefaultBodyDef();
    groundDef.position = b2Vec2(0.0f, -10.0f);
    b2BodyId ground = b2CreateBody(world, &groundDef);
    b2Polygon groundBox = b2MakeBox(50.0f, 10.0f);
    b2ShapeDef groundShape = b2DefaultShapeDef();
    b2CreatePolygonShape(ground, &groundShape, &groundBox);

    // A falling box.
    b2BodyDef bodyDef = b2DefaultBodyDef();
    bodyDef.type = b2BodyType.b2_dynamicBody;
    bodyDef.position = b2Vec2(0.0f, 8.0f);
    b2BodyId box = b2CreateBody(world, &bodyDef);
    b2Polygon dynamicBox = b2MakeBox(0.5f, 0.5f);
    b2ShapeDef shapeDef = b2DefaultShapeDef();
    shapeDef.density = 1.0f;
    b2CreatePolygonShape(box, &shapeDef, &dynamicBox);

    foreach (_; 0 .. 90)
    {
        b2World_Step(world, 1.0f / 60.0f, 4);
        b2Vec2 p = b2Body_GetPosition(box);
        // use p ...
    }
}
```

Run the bundled example:

```sh
dub run box2d:hello
```

## API layout

Import `box2d` to get everything, or import a focused module:

| Module                 | Contents |
|------------------------|----------|
| `box2d.base`           | allocator / assert / log overrides, versioning, timing |
| `box2d.id`             | opaque handle id types (`b2WorldId`, `b2BodyId`, …) |
| `box2d.constants`      | tuning constants |
| `box2d.math_functions` | vector math types and functions (`b2Vec2`, `b2Rot`, …) |
| `box2d.collision`      | geometry, distance, manifolds, the dynamic tree |
| `box2d.types`          | world/body/shape/joint definitions, events, debug draw |
| `box2d.functions`      | the main world/body/shape/joint API |

### D conveniences

The bindings mirror the C API name-for-name (`b2CreateWorld`, `b2World_Step`,
…), so the [official Box2D documentation](https://box2d.org/documentation/)
applies directly. On top of that:

- The header-only inline math helpers (`b2Add`, `b2Dot`, `b2MulRot`, …) are
  reimplemented in pure D, so they inline without calling into the C library.
- `b2Vec2` gains idiomatic operator overloads (`a + b`, `a - b`, `s * v`,
  `v * s`, `-v`, `+=`, `-=`, `*=`) in addition to the free functions.
- Enum members are scoped (e.g. `b2BodyType.b2_dynamicBody`).

## Precision

These bindings target the default single-precision Box2D build, so `b2Pos`
aliases `b2Vec2` and `b2WorldTransform` aliases `b2Transform`. Box2D emits a link
error if an application and library disagree on precision, so a mismatch cannot
go unnoticed.

## Updating the vendored Box2D

The Box2D C source lives in `native/box2d` (`include/` + `src/` + a minimal
`CMakeLists.txt`). The upstream commit is recorded in
`native/box2d/COMMIT.txt`. To update, replace `include/` and `src/` from a newer
Box2D checkout, update the bindings, and run the ABI check:

```sh
dub run :abi
```

It compiles the vendored headers with ImportC and compares them against the D
bindings at compile time: every header function, struct and enum must have a D
counterpart with the same signature, layout (size, alignment, field offsets) and
enum values, and every `extern(C)` declaration must link against the library.

## Development

Format and lint with the standard D tools:

```sh
dub run dfmt -- --inplace source/box2d/*.d examples/*.d tests/abi/*.d
dub run dscanner -- --styleCheck --config dscanner.ini source/box2d/
```

Style is pinned by `.editorconfig` (dfmt: 4-space indent, Allman braces) and
`dscanner.ini`. The naming, undocumented-declaration and long-line checks are
relaxed because the bindings deliberately mirror the C API names verbatim.

## License

MIT. See [LICENSE](LICENSE). Box2D is © Erin Catto and also MIT licensed; its
license is preserved at `native/box2d/LICENSE`.
