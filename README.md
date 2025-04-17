# Simulating the lift on flying objects using values from a shaded Viewport texture in a Compute Shader
This project is a demonstration of a novel use of compute shaders. This project was created to inspire developers to think creatively about using compute shaders for various applications. 

## Installation
1. Ensure you have a valid installation of Godot 4.4 - https://godotengine.org/download/
2. Clone this repository into your desired project folder
    - OR download the zip file
3. Open and run the project to verify the installation

## How to use the program
The initial state of the project is with the paper plane scene already loaded in the Main Scene. If you run the program as is, the plane will start slowly descending in the air. It has no thrust and will not rotate unless you rotate it yourself using the arrow keys. The up and down keys control the pitch of the plane, and the left and right keys control the roll of the plane. Using these, you should notice if you pitch the plane completely downwards, it will fall quicker, and if you pitch it back up, it will use the speed it gained while falling to convert the vertical falling speed into a horizontal speed.

Instructions on how to use self-imported models are left below. There is implementation for control surfaces in the case of the paper airplane, all other control surfaces on other objects are left as an exercise to the user to complete.

### To import models
Import the 3D models as you usually would. To use them out of the box you will need to follow the following steps.

1. Override the surface material with the [depthnorm.gdshader file](/Shaders/gdShaders/) (Or a self-made shader material that selectively shades surfaces based on visible layers)
2. Set the visible layers of the composite object to a layer other than a chosen layer - this chosen layer (if selected) will render objects normally. If this visibility layer is not selected in the object, cameras that do not have that visibility layer selected will render the object according to the depth and normal values (Normals in x and z, Depth in y).
3. Input the shader parameters back into the depthnormal.gdshader via the inspector, such as textures and normal maps.
4. Copy the [generic_plane_scene.tscn](/Scenes/) file to create a new scene and name it appropriate to the 3D model you're using.
5. Create an instance of the new scene you edited in steps 2 and 3 and set it to be a child of the PlaneBody node.
6. Orient the object so the the Front, Up, and Right nodes are directly in front of, on top of, and to the right of the object respectively.
7. Select the top-level node (should be a RigidBody3D node), and modify the values under the tabs "Lift application", "Control", and "Damping" to suit the chosen 3D model.
8. Delete the instance of "PlaneScene" in the Main scene (if it is present - will be a child of the DepthNormalSubViewport node), and create an instance of the scene you created in step 4 in its place.

### Options
The plane scenes provided have variables that have been exported to the inspector. These include the coefficient of lift of the plane, whether the lift force is applied centrally, and options on how to control the plane.

These are provided for testing different plane and wing shapes. Here are a few things to note:
- Using control surfaces to control the plane will only work if the force is not being applied centrally.
- If the force is not being applied centrally, the lift becomes incredibly unstable, and more likely than not the object will start spinning uncontrollably.
- Coefficient of lift in reality scales with angle of attack of the wind - this is not implemented in this solution, so constant values are used for coefficient of lift.

# Credits
Certain models and assets were found online. These are listed below. The licenses of the 3D models are included with the models.

- 3D model credits
    - [Cow model](/Assets/models/cow/) : This work is based on "Cow" (https://sketchfab.com/3d-models/cow-99d333e3b4e4470a8d7d38436489c001) by Josué Boisvert (https://sketchfab.com/JosueBoisvert) licensed under CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
    - [F16 model](/Assets/models/f16-c_falcon/) : This work is based on "F16-C Falcon" (https://sketchfab.com/3d-models/f16-c-falcon-4bc2ff75dc584af2afd0aa6bd8b79015) by Carlos.Maciel (https://sketchfab.com/Carlos.Maciel) licensed under CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
    - [Paper plane model](/Assets/models/paper_plane_-_low_poly_game_ready_for_free/) : This work is based on "Paper Plane - Low Poly Game Ready For Free" (https://sketchfab.com/3d-models/paper-plane-low-poly-game-ready-for-free-53c935434bbd4d398bed826b0dd07446) by LittleZCoordinate (https://sketchfab.com/LittleZCoordinate) licensed under CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
    - [Clipmap mesh](/Assets/terrain/clipmap%20mesh/) - Modelled by github user 'dan-tired', but the idea for the technique used was made by user [@actualdevmar](https://www.youtube.com/@actualdevmar) on YouTube

- Texture credits
    - [Green grass texture](/Assets/terrain/Seamless%20green%20grass%20vector%20pattern.jpg) Posted by user @macrovector on [https://www.freepik.com](https://www.freepik.com/free-vector/seamless-green-grass-pattern_13187581.htm#fromView=keyword&page=1&position=0&uuid=7f224797-b11a-4bd8-9119-b7325e457865&query=Grass+Texture)

# License