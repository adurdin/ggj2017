extern vec2 cameraPosition;
extern float cameraScale;

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
{
    textureCoords /= cameraScale;
    textureCoords += cameraPosition;

    return Texel(texture, textureCoords);
}