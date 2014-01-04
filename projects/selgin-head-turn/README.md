selgin-head-turn
================

Gilbert Concepcion (aka "selgin") is a talented artist, animator and Anime Studio user who conceived [a clever approach](http://www.lostmarble.com/forum/viewtopic.php?t=15846) for smoothly animating a turning head. He describes a realistic example [here](https://vimeo.com/28938430) (pass: selgin).

Selgin's approach utilizes advanced masking techniques and fazek's [meshinstance layer script.](http://www.lostmarble.com/forum/viewtopic.php?t=15845). Selgin's approach was almost exactly what I had been looking for. What the approach didn't handle was using switch layers to support Anime Studio's built-in lip syncing. 

This project illustrates a variation on selgin's head turn approach that includes using switch layers for the mouth and jaw.

![](images/Switch-Mouth-and-Chin-640x480.gif)

The project relies on two layer scripts included [in this repo](../../scripts/layer/README.md): GWB_MoveTogethe and GWB_SwitchTogether. The former, a re-factored version of fazek's and ramon0's meshinstance layer script, is used to replicate point motion and curvature across vector layers. The latter replicates switching keyframes across switch layers.

