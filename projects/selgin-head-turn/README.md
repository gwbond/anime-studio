selgin-head-turn
================

[Victor Paredes](http://animadoresporunacausa.blogspot.com) (aka "selgin") is a talented artist, animator and Anime Studio user who conceived [a clever approach](http://www.lostmarble.com/forum/viewtopic.php?t=15846) for smoothly animating a turning head. He describes a realistic example [here](https://vimeo.com/28938430) (pass: selgin). Selgin's approach utilizes advanced masking techniques and fazek's [meshinstance layer script.](http://www.lostmarble.com/forum/viewtopic.php?t=15845)

This project illustrates a variation on selgin's head turn approach that uses switch layers for the mouth and jaw in order to take advantage of Anime Studio's built-in switch layer-based lip syncing.

The project has been tested with Anime Studio Pro 9.5.

![](images/Switch-Mouth-and-Chin-640x480.gif)

### Contents ###

* [Overview](#overview)
  * [Layer Scripts](#layer-scripts)
  * [Masks](#masks)
* [Ideas to Simplify Rigging](#ideas-to-simplify-rigging)
  * [A New Menu Script](#a-new-menu-script)
  * [A New Anime Studio Feature](#a-new-anime-studio-feature)

Overview
--------

![](images/head-turn-action.png)

The project relies on two layer scripts included [in this repo](../../scripts/layer): GWB_MoveTogether and GWB_SwitchTogether. The former, a completely rewritten and refactored version of fazek's and ramon0's meshinstance layer script, is used to replicate point motion and curvature across vector layers. The latter replicates keyframes across switch layers. The approach also relies on animated layer ordering and relatively complex layer masking that derives from selgin's masking approach. Head turn animation is defined as a smart bone action. Compared to the rigging, the actual animation for this project was simple, basically following the same approach selgin demonstrates [here](https://vimeo.com/28938430) (pass: selgin). Selgin also provides a nice demonstration of layer order animation, used for this project's ears, [here](http://www.youtube.com/watch?v=zk--aWuAZnM)

### Layer Scripts ###

A layer naming convention is adopted to convey individual layer functions and their relationships to one another. A layer name in square brackets signifies the layer acts as an invisible mask e.g., "[face]". A layer name of the form "name1 > name2" indicates that the layer, representing "name1", is linked by a layer script to the layer named "name2". For those familiar with the meshinstance layer script, "name2" is acting as a "source" layer and "name1" is acting as a "dup" (duplicate) layer.  For example, the (dup) layer named "face > [face]" indicates that the layer, representing the "face" is linked to the (source) "[face]" layer.

If a switch layer is linked to another layer, then the dup layer's switch keyframes are duplicates of the source layer's e.g., "jaw > [jaw]" keyframes are duplicates of the "[jaw]" layer's keyframes. The [GWB_SwitchTogether](../../scripts/layer/GWB_SwitchTogether.lua) layer script is used to accomplish this behavior. If a vector layer is linked to another layer, then the dup layer's point motion and curvature are duplicates of the source layer's e.g., "[lips].closed > lips.closed" point motion/curvature are duplicates of the "lips.closed" layer's point motion/curvature. The [GWB_MoveTogether](../../scripts/layer/GWB_MoveTogether.lua) layer script is used to accomplish this behavior. 

Because a source layer acts as a "master" layer, and a dup layer acts as a "slave", only "source" layers need to be animated, and "dup" layers are automatically animated via the layer scripts. In this project, only the "[jaw]" switch layer is used to animate switching behavior of the other three linked switch layers e.g., when the active sub-layer of the "[jaw]" switch layer is "[jaw].open", then all the linked layers switch to their respective ".open" sub-layers. And only the point motion/curvature of the vector layers "[jaw].open", "[jaw].close", "lips.open", "lips.close" and "[face]" need to be modified because the point motion/curvature of other five linked vector layers are updated automatically e.g., changing the point motion/curvature of the "lips.open" layer automatically updates the point motion curvature of the linked "[lips].open > lips.open" layer.

### Masks ###

Here's an overview of the project's masks. If you're not completely comfortable with Anime Studio masking - and you defintely need to be comfortable with masking to understand how masking is used here - then I recommend taking a look at the [series of masking examples](../masking-tests) I put together to help me understand masking. For the impatient, the take-away from these exercises is:  **masks are constructed and applied bottom-up,** starting with the mask of the containing group layer, and then proceeding from the lowest layer in the group to the top layer.

So let's start with the bottom-most mask and work our ways upwards. The bottom-most mask is defined by the containing "head" group, and is set to "hide all."

![](images/head.png)

Moving up the group, the "neck" layer is not masked, but simply occluded by visible layers above it. The next mask is the "[face]" mask which is invisibly added to the "head" mask. The "[face]" mask serves to clip the visible "mouth", "lips > [jaw]", and "eyes" layers when they extend outside the mask boundary. 

![](images/face-mask.png)

Next up is the "[jaw]" mask which is a switch layer because the jaw moves as the lips move. The currently active "[jaw]" sub-layer is added invisibly to the "[face]" mask and serves the same purpose as the "[face]" mask: to clip the visible "mouth", "lips > [jaw]", and "eyes" layers when they extend outside the mask boundary. 

![](images/jaw-mask.png)

![](images/jaw-mask-open.png)

The "mouth" layer contains visible objects depicting teeth and the inside of the mouth. This layer is masked so that it is clipped when positioned outside the underlying "[face]" and "[jaw]" layer masks.

![](images/mouth.png)

Above the "mouth" is the "lips > [jaw]" switch layer, representing the currently active lip position. This visible layer is masked so that it is clipped by the underlying masks when the lips extend outside the mask boundary. The lips object itself consists of a stroked rectangle with transparent fill so that the underlying mouth objects appear through the lips.

![](images/lips.png)

![](images/lips-open.png)

Next is the "[lips] > [jaw]" switch mask layer. In contrast to previous mask layers, this layer invisbly subtracts from the underlying mask, leaving a lips-shaped hole the mask. Note that, in general, the hole must be a filled object in order to act as a mask. The resulting mask, applied to visible layers above it, namely the "face > [face]" and "jaw > [jaw]" layers, allows the underlying "lips > [jaw]" and "mouth" layers to be visible through the hole.

![](images/lips-mask.png)

![](images/lips-mask-open.png)

The  "face > [face]" layer is the masked visible face and the "jaw > [jaw]" switch layer is the masked visible jaw. As described above, the underlying mask applied to these layers cuts a lip-shaped hole in the face through which the underlying "lips > [jaw]" and "mouth" layers appear.

![](images/face.png)

![](images/jaw.png)

![](images/jaw-open.png)

Finally, there are the masked visible "eyes", unmasked visible "left ear" and "right ear", and unmasked visible "nose" layers. Being masked, the "eyes" layer is clipped by the underlying masks when the eyes extend outside the underlying mask boundary.

![](images/eyes.png)

![](images/ear.png)

![](images/nose.png)

Ideas to Simplify Rigging
-----------------------------

It's easy to imagine ways the rigging and head turn animation could be simplified.

### Eliminate the "jaw" switch layers ###

For a simple animated face, it may be sufficient to animate only the lips but not the jaw. In this case, the jaw switch layers can be eliminated, and the jaw would simply be drawn as part of the face.

### Auto-Masking and Auto-Scripting ###

One way to simplify rigging would be to create a menu script that generates the mask layers and adds the layer scripts for a given "head" group consisting of visible "face", "jaw", "lips", and "eyes" layers. I haven't checked the Anime Studio [scripting API](http://www.animestudioscripting.com/) to confirm whether this is possible though.

### Linked Layers ###

Going beyond scripting, it occurs to me that Anime Studio could include a new feature that obviates the need for the two scripts used in this project. The new feature would allow the creation of a new layer type: a "linked layer." When a new linked layer is created, you specify the layer it's linked to, and you specify what properties of the linked layer you want the new layer to copy e.g., the linked layer's points and their associated motion and curvature, or the linked layer's switch keyframes, assuming the linked layer is a switch layer. While unlinked properties, such as masking, can be modified on the new layer, Anime Studio would ensure the user can't modify the linked properties. Anime Studio would also provide the option of hiding linked layers to reduce clutter for the animator.

### Reversed Smart-Bone Actions ###

When rigging a head turn, one must create two smart-bones actions: one for clockwise head turn and the other for counter-clockwise head turn. The only difference between the two is that the keyframe sequences for one action is the reverse of the other action. Today, one must manually create both sequences. A proposed new Anime Studio feature would simply create the reversed sequence for a smart-bone given a sequence for an existing smart-bone.

### Symmetric Smart-Bone Actions and Symmetric Drawing ###

When creating a smart-bone action for a head turn, one creates a keyframe sequence that defines the 360 degree progression of the face turning from front view to profile view to back of head view to opposite profile and then returning to front. For anything but the simplest heads, defining the keys for half the head turn i.e., from front to profile to back, can result in many keyframes on many layers. When the head is symmetric or nearly symmetric, which is often the case, creating the keyframes for the remaining half of the head turn requires creating mirror-image keyframes for the opposite side of the head. This task is complicated by the fact that there is no support for comparing one profile view with the mirror image view when adjusting point positions. Assuming a symmetric face, the proposed new feature would generate the keyframes for half of the turn based on the keyframes already defined for the other half of the turn. In order to make this work, there would initially have to be perfect point symmetry for the face, which brings us to the next new feature...

A related new feature would support symmetric drawing along an axis. Any points placed on one side of the axis would appear in mirror-image on the other side. A closed curve on one side of the axis would result in the creation of a mirror-image closed curve on the other side. A closed curve extending across the axis would be created when the two end points of an open curve on one side of the axis are placed on the axis. Using this feature a completely symmetric face could be constructed. Then, using the aforementioned symmetric smart-bone actions feature, half of the the head turn keyframing could be automatically generated based on the first half. After this is done, one could disable symmetric drawing support, thereby allowing one to introduce asymmetries to the head and to the head turn keyframing.

The benefit of these two new features would be to remove much of the drudgery currently associated with creating a head and animating a head turn, thereby allowing one to concentrate on the creative aspects of drawing and animation.