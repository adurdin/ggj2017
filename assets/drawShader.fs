extern vec2 cameraPosition;
extern float cameraScale;

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
{
    vec2 tansformedTextureCoords = textureCoords * cameraScale;
    tansformedTextureCoords = textureCoords + cameraPosition;

    // textureCoords = textureCoords - vec2(0.1f, 0.0f);

    return Texel(texture, textureCoords);
}