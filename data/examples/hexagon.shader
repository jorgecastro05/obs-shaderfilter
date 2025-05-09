// Hexagon shader by Charles Fettinger for obs-shaderfilter plugin 4/2019
//https://github.com/Oncorporation/obs-shaderfilter
//Converted to OpenGL by Q-mii & Exeldro February 25, 2022
uniform float4 Hex_Color;
uniform int Alpha_Percent<
    string label = "Alpha percent";
    string widget_type = "slider";
    int minimum = 0;
    int maximum = 100;
    int step = 1;
> = 100;
uniform float Quantity<
    string label = "Quantity";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 0.01;
> = 25;
uniform int Border_Width<
    string label = "Border Width";
    string widget_type = "slider";
    int minimum = 0;
    int maximum = 115;
    int step = 1;
> = 15;  // <- -15 to 85, -15 off top
uniform bool Blend;
uniform bool Equilateral;
uniform bool Zoom_Animate;
uniform int Speed_Percent<
    string label = "Speed Percent";
    string widget_type = "slider";
    int minimum = 0;
    int maximum = 100;
    int step = 1;
> = 100; 
uniform bool Glitch;
uniform float Distort_X<
    string label = "Distort X";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 10.0;
    float step = 0.01;
> = 1.0;
uniform float Distort_Y<
    string label = "Distort Y";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 10.0;
    float step = 0.01;
> = 1.0;
uniform float Offset_X<
    string label = "Offset X";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.001;
> = 0.0;
uniform float Offset_Y<
    string label = "Offset X";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.001;
> = 0.0;
uniform string notes<
    string widget_type = "info";
>= "Tiles:equilateral: around 12.33,nonequilateral: square rootable number. Distort of 1 is normal.";

float mod(float x, float y)
{
    return x - y * floor(x/y);
}

float2 mod2(float2 x, float2 y)
{
    return x - y * floor(x/y);
}

// 0 on edges, 1 in non_edge
float hex(float2 p) {
	float xyratio = 1;
	if (Equilateral)
		xyratio = uv_size.x /uv_size.y;

	// calc p 
	p.x = mul(p.x,xyratio);
	p.y += mod(floor(p.x) , 2.0)*0.5;
	p = abs((mod2(p , float2(1.0, 1.0)) - 0.5));
	return abs(max(p.x*1.5 + p.y, p.y*2.0) -1);
}

float4 mainImage(VertData v_in) : TARGET
{
	float4 rgba 		= image.Sample(textureSampler, v_in.uv * uv_scale + uv_offset);
	float alpha 		= float(Alpha_Percent) * 0.01;	
	float quantity 		= sqrt(clamp(Quantity, 0.0, 100.0));
	float border_width	= clamp(float(Border_Width - 15), -15, 100) * 0.01;
	float speed 		= float(Speed_Percent) * 0.01;
	float time 		= (1 + sin(elapsed_time * speed))*0.5;
	if (Zoom_Animate)
		quantity 	*= time;

	// create a (pos)ition reference, hex radius and smoothstep out the non_edge
	float2 pos 		= float2(v_in.uv.x * max(0,Distort_X), (1 - v_in.uv.y) * max(0,Distort_Y)) * uv_scale + uv_offset + float2(Offset_X, Offset_Y);
	if (Glitch)
		quantity 	*= lerp(pos.x, pos.y, rand_f);
	float2 p 		= (pos * quantity); // number of hexes to be created
	float  r 		= (1.0 -0.7)*0.5;	// cell default radius
	float non_edge 		= smoothstep(0.0, r + border_width, hex(p)); // approach border become edge

	// make the border colorable - non_edge is scaled
	float4 c = float4(non_edge, non_edge,non_edge,1.0) ;
	if (non_edge < 1)
	{
		c = Hex_Color;
		c.a = alpha;
		if (Blend)
			c = lerp(rgba, c, 1 - non_edge);
		return lerp(rgba,c,alpha);
	}
	return lerp(rgba, c * rgba, alpha);
} 
