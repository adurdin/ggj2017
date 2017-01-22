#define M_PI 3.1415926535897932384626433832795

extern vec2 cameraPosition;
extern float cameraScale;
extern bool polarRendering;

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
{
    /* camera transform */
    textureCoords /= cameraScale;
    textureCoords += cameraPosition;
    
    /* polar tranform */
    if (polarRendering) {
      textureCoords += vec2(-0.5f, -0.5f);
      float radius = 1.0f - length(textureCoords);
      float angle = (M_PI + atan(textureCoords.y, textureCoords.x)) / (2 * M_PI);
      textureCoords = vec2(angle, radius * 0.6f);
    }

    return Texel(texture, textureCoords);
}