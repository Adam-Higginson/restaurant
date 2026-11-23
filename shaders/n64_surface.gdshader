// How models fired in the Kiln are drawn, lit per pixel (the usual way).
// Everything but the lighting is shared with n64_surface_vertex, in
// n64_surface.gdshaderinc.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

#include "res://shaders/n64_surface.gdshaderinc"
