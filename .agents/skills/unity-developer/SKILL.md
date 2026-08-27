---
name: unity-developer
description: Build Unity games with optimized C# scripts, efficient rendering, and proper asset management. Masters Unity 6 LTS, URP/HDRP pipelines, and cross-platform deployment. Handles gameplay systems, UI implementation, and platform optimization. Use PROACTIVELY for Unity performance issues, game mechanics, or cross-platform builds.
---

# Unity Game Development & Optimization (unity-developer)

Expert guidelines for building high-performance 3D/2D games, vehicle physics, drift mechanics, URP rendering, and Android mobile optimization.

---

## 1. When to Use & Triggers
- Developing Unity games, vehicle physics, drift controllers, and camera systems.
- Optimizing frame rates (Draw Calls, SetPass calls, GPU/CPU bottlenecks) on Android/mobile.
- Structuring C# gameplay architecture, ScriptableObjects, and event-driven patterns.
- Configuring Universal Render Pipeline (URP), lightmaps, shaders, and occlusion culling.

---

## 2. What TO Do (Core Principles)
- **Zero Garbage Collection in Update:** Avoid allocations, string concatenations, or GetComponent inside Update().
- **Vehicle Physics:** Use dedicated Raycast or WheelCollider physics with custom slip curves for smooth drift mechanics.
- **Batching & Draw Calls:** Use Static/Dynamic Batching, GPU Instancing, and Texture Atlases for high mobile frame rates.
- **ScriptableObjects:** Decouple data architecture using ScriptableObjects for car stats, levels, and configurations.

---

## 3. What NOT To Do
- ❌ Do NOT call Find(), FindObjectOfType(), or GetComponent() inside Update() loops.
- ❌ Do NOT use high-poly unoptimized meshes or uncompressed 4K textures on mobile Android builds.
- ❌ Do NOT use heavy real-time shadows on mobile; use baked lightmaps.

---

## 4. Step-by-Step Workflow
1. **Core Mechanics & Physics:** Implement kinematic or physics-based controllers in FixedUpdate().
2. **UI & Canvas Setup:** Build responsive UI using Canvas Scaler and TextMeshPro.
3. **Lighting & Baking:** Set up URP lighting, bake lightmaps, and enable Occlusion Culling.
4. **Profiling & Optimization:** Run Unity Profiler to eliminate GC spikes and reduce draw calls under 100.
5. **Build & Deploy:** Build Android APK / AAB and verify performance on real devices.

---

## 5. Production Checklist
- [ ] Are all Update() loops free of allocations and GetComponent calls?
- [ ] Are draw calls under 100-150 for mobile targets?
- [ ] Is Occlusion Culling baked and verified?
- [ ] Are texture compression formats set to ASTC for Android?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Coordinates with clean-code-architect for C# architecture standards.
- ➔ Works with qa-testing-quality for gameplay performance benchmarks.
