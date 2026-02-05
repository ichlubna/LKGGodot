# LKG Godot
This repository contains a sample project with a 3D scene rendered for a use with a 3D display by Looking Glass Factory. 
This sample does not use the Looking Glass Factory Bridge driver. 
Therefore, the calibration parameters of the given display model need to be manually set in the `HoloCamera.tscn` properties.
`HoloCamera.tscn, holo.gdshader, holoCameraGenerator.gd` assets can be imported to other projects as well.
`HoloCamera.tscn` is a camera object that internally contains multiple cameras for the 3D display. 
