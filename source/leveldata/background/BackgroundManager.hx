package leveldata.background;

import shaders.*;
import backgrounds3D.*;
import openfl.display.BitmapData;
import main.mods.ModLoader;
import main.ChapterState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObjectLayer;

class BackgroundManager 
{
    private static function getScrollBoost(tiledData:TiledMap):Float
    {
        var scrollSettingsLayer = tiledData.getLayer("ScrollSettings");
        if (scrollSettingsLayer != null && scrollSettingsLayer.type == TiledLayerType.OBJECT)
            {
            var castScroll:TiledObjectLayer = cast scrollSettingsLayer;
            if (castScroll.properties.contains("speed"))
            {
                return Std.parseFloat(Std.string(castScroll.properties.get("speed")));
            }
                
            }
        return 0;
    }

    public static function updateAllEffects(state:ChapterState, tiledData:TiledMap):Void
    {
        updateBackground(state, tiledData);
        updateShader(state, tiledData);
        bgDecoEffect(state, tiledData);
        bgEffect(state, tiledData);
        bgEffectDouble(state, tiledData);
        foregroundEffect(state, tiledData);
        topEffect(state, tiledData);
    }

    public static function updateBackground(state:ChapterState, tiledData:TiledMap):Void
    {
        var bgLayer = tiledData.getLayer("bg");
        var isScrolling:Bool = true;

        if (bgLayer == null || !bgLayer.properties.contains("bgName")) return;

        var newBG:String = bgLayer.properties.get("bgName");
        var scrollText = bgLayer.properties.get("scrolls");

        if (scrollText != null && scrollText == "false") isScrolling = false; 

        if (newBG != state.currentBGName)
        {
            if (state.bg != null)
            {
                state.remove(state.bg);
                state.bg.destroy();
                state.bg = null;
            }

            #if sys
            var bgPath = ModLoader.getAsset("images/backgrounds/" + newBG + ".png");
            var bmp = BitmapData.fromFile(bgPath);
            if (bmp == null)
            {
                trace("FAILED TO LOAD BG: " + bgPath);
                return;
            }
            state.bg = new FlxBackdrop(bmp);
            #else
            state.bg = new FlxBackdrop("assets/images/backgrounds/" + newBG + ".png");
            #end
            state.bg.velocity.set(0, 0);
            if (isScrolling) state.bg.scrollFactor.set(0.15, 0);
            else state.bg.scrollFactor.set(0, 0);
            state.bg.active = false;

            if (state.currentRoomName != null && StringTools.startsWith(state.currentRoomName, "boss-jevil")
                && state.currentRoomName != null && !StringTools.startsWith(state.currentRoomName, "boss-jevil05"))
            {
                state.bg.alpha = 0;
            }

            state.currentBGName = newBG;
            state.insert(0, state.bg);
        }

    }

    public static function updateShader(state:ChapterState, tiledData:TiledMap):Void
    {
        var bgLayer = tiledData.getLayer("bg");
        if (bgLayer == null || state.bg == null) return;

        if (bgLayer.properties.contains("bgShader"))
        {

            switch (bgLayer.properties.get("bgShader"))
            {
                case "sunset":
                    state.sunsetShader = new SunsetRayShader(0.5, 5);
                    state.sunsetShader.data.time.value = [0.0];
                    state.bg.shader = state.sunsetShader;

                case "circus":
                    state.circusShader = new JevilCircusBG();
                    state.circusShader.data.time.value = [0.0];
                    state.bg.shader = state.circusShader;

                case "rainbow":
                    state.rainbowShader = new RainbowCrazy();
                    state.rainbowShader.data.time.value = [0.0];
                    state.bg.shader = state.rainbowShader;

                case "rain":
                    state.rainShader = new RainShader();
                    state.rainShader.data.time.value = [0.0];
                    state.bg.shader = state.rainShader;

                case "castle":
                    state.castleShader = new CastleIndoors();
                    state.castleShader.data.time.value = [0.0];
                    state.bg.shader = state.castleShader;

                case "toxic":
                    state.toxicShader = new ToxicShader();
                    state.toxicShader.data.time.value = [0.0];
                    state.bg.shader = state.toxicShader;
            }
        }
        else
        {
            state.bg.shader = null;
            state.circusShader = null;
            state.rainbowShader = null;
            state.rainShader = null;
            state.castleShader = null;
            state.toxicShader = null;
        }
        
    }

    public static function bgDecoEffect(state:ChapterState, tiledData:TiledMap):Void
    {
        var layer = tiledData.getLayer("mapDecoEffect");
        var boost = getScrollBoost(tiledData);

        if (layer != null && layer.properties.contains("backDecoEffectType"))
            {
            var effect = layer.properties.get("backDecoEffectType");
            if (effect != state.currentBackDecoEffectName || boost != state.lastDecoScrollBoost)

            if (effect == "none" || effect == "")
            {
                if (state.backDecoEffectObj != null)
                {
                    state.remove(state.backDecoEffectObj);
                    state.backDecoEffectObj.destroy();
                    state.backDecoEffectObj = null;
                }

                state.currentBackDecoEffectName = effect;
                state.lastDecoScrollBoost = boost;

                return;
            }


            {
                if (state.backDecoEffectObj != null) { state.remove(state.backDecoEffectObj); state.backDecoEffectObj.destroy(); }

                switch (effect)
                {
                    case "moon":
                        state.backDecoEffectObj = new FlxBackdrop(AssetPaths.moon__png, X);
                        state.backDecoEffectObj.velocity.set(-5, -3);
                    case "clouds":
                        state.backDecoEffectObj = new FlxBackdrop(AssetPaths.cloudsBack__png, XY);
                        state.backDecoEffectObj.velocity.set(-30, 0);
                        state.backDecoEffectObj.alpha = 0.65;

                }
                if (state.backDecoEffectObj != null)
                {
                    state.backDecoEffectObj.scrollFactor.set(0, 0);
                    state.currentBackDecoEffectName = effect;
                    state.lastDecoScrollBoost = boost;
                    state.insert(1, state.backDecoEffectObj);
                }
            }
        }
    }

    public static function bgEffect(state:ChapterState, tiledData:TiledMap):Void
    {
        var layer = tiledData.getLayer("mapEffect");
        var boost = getScrollBoost(tiledData);

        if (layer != null && layer.properties.contains("effectType"))
        {
            var effect = layer.properties.get("effectType");

            if (effect == state.currentBackEffectName && boost == state.lastBackScrollBoost)
            {
                return;
            }

            if (effect == "none" || effect == "") // There's no BG effect here
            { 
                if (state.backEffectObj != null)
                {           
                    state.remove(state.backEffectObj);
                    state.backEffectObj.destroy();
                    state.backEffectObj = null;
                    state.currentBackEffectName = "";
                }
                return;
            }

            if (state.backEffectObj != null) // The effect IS DIFFERENT
            { 
                state.remove(state.backEffectObj); 
                state.backEffectObj.destroy();
                state.backEffectObj = null;
            }

            switch (effect)
            {
                
                case "fog":
                    state.backEffectObj = new FlxBackdrop(AssetPaths.white_fog__png, X);
                    state.backEffectObj.velocity.set(-50 - boost, 0);
                    state.backEffectObj.alpha = 0.2;

                case "poison-fog":
                    state.backEffectObj = new FlxBackdrop(AssetPaths.poison_fog__png, XY);
                    state.backEffectObj.velocity.set(60, 0);
                    state.backEffectObj.alpha = 0.5;
                case "circus":
                    
                    if (state.circusBG == null)
                    {
                        state.circusBG = new leveldata.backgrounds3D.CircusBackground();
                        state.circusBG.canvas.scrollFactor.set(0, 0);
                    }

                    state.insert(1, state.circusBG);

                    state.currentBackEffectName = effect;
                    state.lastBackScrollBoost = boost;


            }

            if (state.backEffectObj != null)
            {
                state.backEffectObj.scrollFactor.set(0, 0);
                state.currentBackEffectName = effect;
                state.lastBackScrollBoost = boost;
                state.insert(2, state.backEffectObj);
            }
        }
    }

    public static function bgEffectDouble(state:ChapterState, tiledData:TiledMap):Void
    {
        var layer = tiledData.getLayer("doubleEffect");
        var boost = getScrollBoost(tiledData);

        if (layer != null && layer.properties.contains("doubleEffectType"))
        {
            var effect = layer.properties.get("doubleEffectType");
            
            if (effect != state.currentDoubleEffectName || boost != state.lastDoubleScrollBoost)
            { 
                if (effect == "none" || effect == "")
                { 
                    if (state.doubleEffectObj != null)
                    {
                        state.remove(state.doubleEffectObj);
                        state.doubleEffectObj.destroy();
                        state.doubleEffectObj = null;
                    }
                    state.currentDoubleEffectName = effect;
                    return;
                }

                if (state.doubleEffectObj != null) 
                { 
                    state.remove(state.doubleEffectObj); 
                    state.doubleEffectObj.destroy(); 
                    state.doubleEffectObj = null;
                }

                switch (effect)
                {
                    case "dark-cloud":
                        state.doubleEffectObj = new FlxBackdrop(AssetPaths.cloudsPixel__png, X);
                        state.doubleEffectObj.velocity.set(360 - boost, 0);
                        state.doubleEffectObj.alpha = 1;
                    case "redMist":
                        state.doubleEffectObj = new FlxBackdrop(AssetPaths.redMist__png, X);
                        state.doubleEffectObj.velocity.set(-10, 0);
                        state.doubleEffectObj.alpha = 0.15;

                }

                if (state.doubleEffectObj != null)
                {
                    state.doubleEffectObj.scrollFactor.set(0, 0);
                    state.currentDoubleEffectName = effect;
                    state.lastDoubleScrollBoost = boost;
                    state.insert(3, state.doubleEffectObj);
                }
            }
        }
    }

    public static function foregroundEffect(state:ChapterState, tiledData:TiledMap):Void
    {
        var layer = tiledData.getLayer("foregroundEffect");
        var boost = getScrollBoost(tiledData);

        if (layer != null && layer.properties.contains("foregroundEffectType"))
        {
            var effect = layer.properties.get("foregroundEffectType");
            if (effect != state.currentFrontEffectName || boost != state.lastFrontScrollBoost)
            { 
                if (effect == "none" || effect == "" || layer == null)
                { 
                    if (state.frontEffectObj != null) 
                    {
                        state.remove(state.frontEffectObj);
                        state.frontEffectObj.destroy();
                        state.frontEffectObj = null;
                    }
                    state.currentFrontEffectName = effect; 
                    state.lastFrontScrollBoost = boost;
                    return;
                }
                if (state.frontEffectObj != null) 
                { 
                    state.remove(state.frontEffectObj); 
                    state.frontEffectObj.destroy(); 
                    state.frontEffectObj = null;
                }
                switch (effect)
                {
                    
                    case "rain":
                        state.frontEffectObj = new FlxBackdrop(AssetPaths.rain__png, XY);
                        state.frontEffectObj.velocity.set(-250, 1200);
                        state.frontEffectObj.alpha = 0.15;

                    case "toxic":
                        state.frontEffectObj = new FlxBackdrop(AssetPaths.poison_air__png, X);
                        state.frontEffectObj.velocity.set(35, 0);
                        state.frontEffectObj.alpha = 1;
                        
                    case "sandstorm":
                        state.frontEffectObj = new FlxBackdrop(AssetPaths.sandstorm__png, X);
                        state.frontEffectObj.velocity.set(boost - 3000, 0);

                }

                if (state.frontEffectObj != null)
                {
                    state.frontEffectObj.scrollFactor.set(1, 0);
                    state.currentFrontEffectName = effect;
                    state.lastFrontScrollBoost = boost;
                    state.add(state.frontEffectObj);
                }
            }
        }
    }

    public static function topEffect(state:ChapterState, tiledData:TiledMap):Void
    {
        var layer = tiledData.getLayer("topEffect");
        var boost = getScrollBoost(tiledData);

        if (layer != null && layer.properties.contains("topEffectType"))
            {
            var effect = layer.properties.get("topEffectType");
            if (effect != state.currentTopEffectName || boost != state.lastTopScrollBoost)

            if (effect == "none" || effect == "")
            {
                if (state.topEffectObj != null)
                {
                    state.remove(state.topEffectObj);
                    state.topEffectObj.destroy();
                    state.topEffectObj = null;
                }

                state.currentTopEffectName = effect; 
                state.lastTopScrollBoost = boost;
                return;
            }

            {
                if (state.topEffectObj != null) { state.remove(state.topEffectObj); state.topEffectObj.destroy(); }

                switch (effect)
                {
                    case "speed":
                        state.topEffectObj = new FlxBackdrop(AssetPaths.speed_lines__png, X);
                        state.topEffectObj.velocity.set(boost - 3000, 0);
                    case "wind":
                        state.topEffectObj = new FlxBackdrop(AssetPaths.wind__png, XY);
                        state.topEffectObj.velocity.set(-1000, 200);
                        state.topEffectObj.alpha = 0.3;
                }
                if (state.topEffectObj != null)
                {
                    state.topEffectObj.scrollFactor.set(2, 0);
                    state.currentTopEffectName = effect;
                    state.lastTopScrollBoost = boost;
                    state.add(state.topEffectObj);
                }
            }
        }
    }

}