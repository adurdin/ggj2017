vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
{
    vec2 transformedCoords = (textureCoords * vec2(1.0f, 1.25f)) + vec2(0.0f, -0.4f);
    
    vec4 pixel = Texel(texture, transformedCoords);
        
    return pixel;
}