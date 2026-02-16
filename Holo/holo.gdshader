shader_type canvas_item;

//uniform sampler2D screenTexture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D screenTexture : repeat_disable, filter_linear;
uniform float tilt = 0.0;
uniform float pitch = 0.0;
uniform float center = 0.0;
uniform float viewPortionElement = 1.0;
uniform float subp = 0.0;
uniform float quiltAspect = 0.0;
uniform float invertedScreenAspect = 0.0;
uniform int viewCount = 1;
uniform int cols = 1;
uniform int rows = 1;
uniform int mode = 0;

const int CENTER = 0;
const int QUILT = 1;
const int DISPLAY = 2;

vec2 scaleAndCenter(vec2 coords)
{
	coords.y -= 0.5;
	coords.y *= 1.0/quiltAspect;
	coords.y += 0.5;
	if(quiltAspect <= 1.0)
	{
		coords.y -= 0.5;
		coords.y *= invertedScreenAspect*quiltAspect;
		coords.y += 0.5;
		coords.x -= 0.5;
		coords.x *= invertedScreenAspect*quiltAspect;
		coords.x += 0.5;
	}
	return coords;
}

vec2 texArr(vec3 uvz) {
    float z = floor(uvz.z * float(viewCount));
	z = float((int(z)%cols)+(rows-1-int(z)/cols)*cols);
	uvz.xy = scaleAndCenter(uvz.xy);
	float x = (mod(z, float(cols)) + uvz.x) / float(cols);
    float y = (floor(z / float(cols)) + uvz.y) / float(rows);
    return vec2(x, y) * vec2(viewPortionElement, viewPortionElement);
}

vec4 createHoloView(vec2 uv) {
    float invView = 1.0;
    int ri = 0;
    int bi = 2;

    vec3 nuv = vec3(uv, 0.0);
    vec4 rgb[3];

    for (int i = 0; i < 3; i++) {
        nuv.z = (uv.x + float(i) * subp + uv.y * tilt) * pitch - center;
        nuv.z = mod(nuv.z + ceil(abs(nuv.z)), 1.0);
        nuv.z = (1.0 - invView) * nuv.z + invView * (1.0 - nuv.z);
        vec2 coords = texArr(nuv);
        rgb[i] = texture(screenTexture, coords);
    }

    return vec4(rgb[ri].r, rgb[1].g, rgb[bi].b, 1.0);
}

void fragment() {
	if (mode == CENTER) {
		vec2 view = vec2(1.0/float(cols), 1.0/float(rows));
		vec2 shift = vec2(round(float(cols-1)/2.0), round(float(rows-1)/2.0));
		vec2 coords = UV*view+view*shift;
		coords = scaleAndCenter(coords);
		COLOR = texture(screenTexture, coords);
	} else if (mode == QUILT) {
        COLOR = texture(screenTexture, UV);
    } else if (mode == DISPLAY) {
        COLOR = createHoloView(UV);
    }
}