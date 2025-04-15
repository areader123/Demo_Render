LoneStack v1.0

is a custom post processing tool for the Universal Render Pipeline made by Alain St-Raymond.
With it you will be able to stack post processing effects, make them collider-reliant, visualize them in scene view,
create and use post processing profiles, modify effects at runtime, and create scripted post processing effects and effect editors.

<!> Moving the LoneStack folder in your project may result in some builtin effect shaders and script generators to stop working.

-- Setup --
-> add the LoneStack RenderFeature to your camera's renderer's render features.
== this was the least intuitive step, the rest can be figured out on your own, mostly if you've had experience with the PostProcessingStack v2.
-> add an LSLayer to your camera.
-> Create an object and add an LSVolume to it.
== at this point you can already add effects on your volumes and visualize them. (but the effects aren't saved yet)
-> Create a LSProfile Asset and Link it to your LSVolume.
-> Apply the volumes effects to the profile to save them, Reset the Volume's effects to copy/activate the current profile's effects.
== the rest is just about having fun.

-- How it works --
> Pipeline
Camera >> Renderer >> LoneStack RenderFeature >> [CommandBuffer creation] >> Camera's LSLayer >> [foreach] Appropriate LSVolumes >> [foreach] Volume's effects >> enqueue effect to CommandBuffer >> [CommandBuffer execution]

> Effects Serialization
- A profile contains just a list of <type as string, and Effect settings data serialized to JSon> also called "Effects blueprints".
- These blueprints are then instantiated by the volume.
- The volume can also create blueprints of its active effects.