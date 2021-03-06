#define M_PI 3.1415926535897932384626433832795

extern float screenAspect;
extern float worldAspect;
extern vec2 cameraPosition;
extern float cameraScale;
extern bool polarRendering;
extern float polarRotation;

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
{
    /* camera transform */
    textureCoords /= cameraScale;
    textureCoords += cameraPosition;
    
    /* polar tranform */
    if (polarRendering) {
      textureCoords *= vec2(worldAspect, 1.0f);
      textureCoords += vec2(-screenAspect / 2.0f, -0.5f);
      float radius = 1.414f - length(textureCoords);
      float angle = M_PI + atan(textureCoords.y, textureCoords.x);
      textureCoords = vec2((angle + polarRotation) / (2 * M_PI), radius * 0.6f);
    }

    return Texel(texture, textureCoords);
}