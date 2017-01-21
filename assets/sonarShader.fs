#define M_PI 3.1415926535897932384626433832795

extern vec2 sourcePosition;
extern float radius;
extern float maxTime;
extern float currentTime;
uniform Image densityMap;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 density = Texel(densityMap, texture_coords);
    
    vec4 pixel = Texel(texture, texture_coords);
    
    float normalizedTime = (currentTime / maxTime);
    float positionInRadius = (1.0f - normalizedTime) * radius;
    
    float distance = sqrt(pow(abs(sourcePosition.x - texture_coords.x), 2) + pow(abs(sourcePosition.y - texture_coords.y), 2));
    float normalizedDistance = distance / radius;
    
    // TODO(Gordon): This is a hack, we need a better solution
    if (!(density.r > 0.9f && density.y < 0.1f)) {
      if (currentTime > 0.0f) {
          if (abs(distance - positionInRadius) < 0.001f) {
              return vec4(0.0f, 1.0f, 0.0f, 1.0f); 
          } else if (distance <= positionInRadius) {
              return pixel * density * vec4(0.0f, abs(sin((normalizedDistance + normalizedTime) * 2 * 8 * M_PI)), 0.0f, 1.0f); 
          } else {
              return pixel;
          }
      }
    }
    return pixel;
}