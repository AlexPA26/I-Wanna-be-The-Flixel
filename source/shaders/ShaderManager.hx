package shaders;

import main.ChapterState;

class ShaderManager 
{
    public static function updateShaders(state:ChapterState, elapsed:Float):Void
    {
        if (state.rainShader != null) state.rainShader.update(elapsed);
        if (state.castleShader != null) state.castleShader.update(elapsed);
        if (state.castleInsideShader != null) state.castleInsideShader.update(elapsed);
        if (state.toxicShader != null) state.toxicShader.update(elapsed);
        if (state.sunsetShader != null) state.sunsetShader.update(elapsed);
        
        if (state.circusShader != null && state.bg != null)
        {
            state.bg.shader = state.circusShader;
            state.bg.x = -200;
            state.circusShader.update(elapsed);
        }

        if (state.rainbowShader != null && state.bg != null)
        {
            state.bg.shader = state.rainbowShader;
            state.rainbowShader.data.time.value[0] += elapsed;
        }

        if (state.screenShader != null)
        {
            try { state.screenShader.data.time.value[0] += elapsed; } catch (e:Dynamic) {}
        }
    }
}