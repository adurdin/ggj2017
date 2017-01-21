#define M_PI 3.1415926535897932384626433832795
#define M_TERRAIN_TYPE_GAS 128
#define M_TERRAIN_TYPE_VOID 129
#define M_TERRAIN_TYPE_SKY 130

extern vec2 sourcePosition;
extern float radius;
extern float maxTime;
extern float currentTime;
extern Image densityMap;
extern float WORLD_HEIGHT;
extern float WORLD_TERRAIN_Y;
extern float WORLD_TERRAIN_SIZE;
extern float SCREEN_HEIGHT;

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
{
    vec4 COLOUR_BLACK = vec4(0.0f, 0.0f, 0.0f, 1.0f);
    vec4 COLOUR_SKY = vec4(0.0f, 0.55f, 0.99f, 1.0f);
    vec4 COLOUR_DIRT = vec4(0.48f, 0.26f, 0.09f, 1.0f);

    /* transforms texture coordinates for density map */                                                               
    vec2 densityMapTextureCoords = textureCoords * vec2(1.0f, SCREEN_HEIGHT / WORLD_TERRAIN_SIZE)
        - vec2(0.0f, WORLD_TERRAIN_Y / WORLD_HEIGHT * SCREEN_HEIGHT / WORLD_TERRAIN_SIZE);
    
    vec4 densityMapPixel = COLOUR_BLACK;
    vec4 finalColourPixel = COLOUR_BLACK;
    float terrainType = 0;
    
    if (densityMapTextureCoords.y < 0.0f) {
        finalColourPixel = COLOUR_SKY;
        terrainType = M_TERRAIN_TYPE_SKY;
    } else if (densityMapTextureCoords.y > 1.0f) {
        finalColourPixel = COLOUR_DIRT;
        // terrainType = M_TERRAIN_TYPE_DIRT;
    } else {
        densityMapPixel = Texel(densityMap, densityMapTextureCoords);
        terrainType = densityMapPixel.a * 255.0f;
        densityMapPixel.a = 1.0f;
        finalColourPixel = vec4(densityMapPixel.r, densityMapPixel.g, densityMapPixel.b, 1.0f);
    }
    
    float normalizedTime = (currentTime / maxTime);
    float positionInRadius = (1.0f - normalizedTime) * radius;
    
    float distance = sqrt(pow(abs(sourcePosition.x - textureCoords.x), 2) + pow(abs(sourcePosition.y - textureCoords.y), 2));
    float normalizedDistance = distance / radius;
    
    if (terrainType != M_TERRAIN_TYPE_SKY) {
        if (currentTime > 0.0f) {
            if (abs(distance - positionInRadius) < 0.001f) {
                return vec4(0.0f, 1.0f, 0.0f, 1.0f);
            } else if (distance <= positionInRadius) {
                if (terrainType == M_TERRAIN_TYPE_GAS || terrainType == M_TERRAIN_TYPE_VOID) {
                    return vec4(0.0f, 0.0f, 0.0f, 1.0f);
                } else {
                    return finalColourPixel * vec4(0.0f, abs(sin((normalizedDistance + normalizedTime) * 2 * 8 * M_PI)), 0.0f, 1.0f);
                }
            } else {
                return finalColourPixel;
            }
        }
    }
    return finalColourPixel;
}