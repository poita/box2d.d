// SPDX-License-Identifier: MIT
/++
    Cross-platform D bindings for Box2D 3.x, the 2D physics engine.

    Import this module to get the whole API:
    ---
    import box2d;
    ---

    See the individual modules for focused imports:
    $(UL
      $(LI $(D box2d.base) — allocator/assert/log overrides, versioning, timing)
      $(LI $(D box2d.id) — opaque handle id types)
      $(LI $(D box2d.constants) — tuning constants)
      $(LI $(D box2d.math_functions) — vector math types and functions)
      $(LI $(D box2d.collision) — geometry, distance, manifolds, dynamic tree)
      $(LI $(D box2d.types) — world/body/shape/joint definitions, events, debug draw)
      $(LI $(D box2d.functions) — the main world/body/shape/joint API)
    )
+/
module box2d;

public import box2d.base;
public import box2d.id;
public import box2d.constants;
public import box2d.math_functions;
public import box2d.collision;
public import box2d.types;
public import box2d.functions;
