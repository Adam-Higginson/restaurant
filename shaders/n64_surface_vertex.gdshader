// How models fired in the Kiln are drawn with the N64's own lighting: worked
// out at each corner and blended across the triangle (Gouraud shading), so a
// lantern passing lights the model in soft gradients across its faces.
// Everything else is shared with n64_surface, in n64_surface.gdshaderinc.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, vertex_lighting;

#include "res://shaders/n64_surface.gdshaderinc"
