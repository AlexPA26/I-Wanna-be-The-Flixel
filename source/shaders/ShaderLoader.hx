package shaders;

import openfl.filters.ShaderFilter;
import flixel.FlxG;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledObjectLayer;
import main.ChapterState;

class ShaderLoader
{
    public static function loadShaders(tiledData:TiledMap, state:ChapterState):Void
    {
        var shaderLayer:TiledLayer = tiledData.getLayer("shaders");

        if (shaderLayer == null || shaderLayer.type != TiledLayerType.OBJECT)
        {
            clearScreenShader(state);
            return;
        }

        var castLayer:TiledObjectLayer = cast shaderLayer;

        if (!castLayer.properties.contains("shaderName"))
        {
            clearScreenShader(state);
            return;
        }

        var shaderName:String = castLayer.properties.get("shaderName");
        if (shaderName == state.screenShaderName && state.screenShader != null)
        {
            return;
        }

        clearScreenShader(state);

        switch (shaderName)
        {
            case "dawn":
                state.screenShader = new SunsetWarmShader();
            case "rain":
                state.screenShader = new RainShader();

            case "radioactive":
                state.screenShader = new RadioactiveShader();

            case "castle":
                state.screenShader = new CastleInside();

            case "castleRays":
                state.screenShader = new CastleIndoors();

            case "rainbow":
                state.screenShader = new RainbowCrazy();

            default:
                trace("[ ShaderLoader ] Unknown shaderName on 'shaders' layer: " + shaderName);
                return;
        }

        state.screenShaderName = shaderName;
        
        FlxG.camera.filters = [new ShaderFilter(state.screenShader)];
    }

    public static function clearScreenShader(state:ChapterState):Void
    {
        if (state.screenShader != null)
        {
            FlxG.camera.filters = [];
        }

        state.screenShader = null;
        state.screenShaderName = null;
    }
}