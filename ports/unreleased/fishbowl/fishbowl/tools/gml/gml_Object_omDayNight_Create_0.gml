store = {};
state = new SnowState("Init");
logStateChange(state);
state.add("Init", 
{
    enter: function()
    {
        store.shader = oShaderApply;
    },
    
    step: function()
    {
        state.change("Morning");
    }
});
state.add("Morning", 
{
    enter: function()
    {
        store.shader.currentShader = "morning";
        hideAllLightLayers();
        layer_set_visible("MorningLight", true);
        layer_set_visible("MorningDust", true);
        instance_activate_layer("MorningLight");
        instance_activate_layer("MorningDust");
        setWindowSprites("day");
        oHomePhone.setWallpaper("Morning");
    },
    
    next: function()
    {
        state.change("Afternoon");
    },
    
    leave: function()
    {
    }
});
state.add("Afternoon", 
{
    enter: function()
    {
        store.shader.currentShader = "afternoon";
        hideAllLightLayers();
        layer_set_visible("AfternoonLight", true);
        instance_activate_layer("AfternoonLight");
        setWindowSprites("day");
        oHomePhone.setWallpaper("Afternoon");
    },
    
    next: function()
    {
        state.change("Evening");
    },
    
    leave: function()
    {
        layer_set_visible("MorningLight", false);
        layer_set_visible("MorningDust", false);
        layer_set_visible("AfternoonLight", false);
    }
});
state.add("Evening", 
{
    enter: function()
    {
        store.shader.currentShader = "evening";
        hideAllLightLayers();
        layer_set_visible("EveningLight", true);
        instance_activate_layer("EveningLight");
        setWindowSprites("day");
        oHomePhone.setWallpaper("Evening");
        if (osmGameData.getCurrentDayNumber() > 25)
        {
            layer_set_visible("FairyLights", true);
            instance_activate_layer("FairyLights");
        }
    },
    
    next: function()
    {
        state.change("Night");
    },
    
    leave: function()
    {
        layer_set_visible("EveningLight", false);
    }
});
state.add("Night", 
{
    enter: function()
    {
        store.shader.currentShader = "night";
        hideAllLightLayers();
        layer_set_visible("NightLight", true);
        instance_activate_layer("NightLight");
        setWindowSprites("night");
        oHomePhone.setWallpaper("Night");
    },
    
    next: function()
    {
    }
});
state.add("Midnight", 
{
    enter: function()
    {
        store.shader.currentShader = "midnight";
        hideAllLightLayers();
        layer_set_visible("MidnightLight", true);
        instance_activate_layer("MidnightLight");
        oHomePhone.setWallpaper("Night");
        if (osmGameData.getCurrentDayNumber() > 25)
        {
            layer_set_visible("FairyLights", true);
            instance_activate_layer("FairyLights");
        }
    },
    
    next: function()
    {
    }
});

hideAllLightLayers = function()
{
    layer_set_visible("MidnightLight", false);
    layer_set_visible("NightLight", false);
    layer_set_visible("MorningLight", false);
    layer_set_visible("MorningDust", false);
    layer_set_visible("AfternoonLight", false);
    layer_set_visible("EveningLight", false);
    instance_deactivate_layer("MidnightLight");
    instance_deactivate_layer("NightLight");
    instance_deactivate_layer("MorningLight");
    instance_deactivate_layer("MorningDust");
    instance_deactivate_layer("AfternoonLight");
    instance_deactivate_layer("EveningLight");
};

getStateNameBasedOnTime = function()
{
    var _time = osmGameData.getDayTime();
    if (_time >= 8 && _time < 12)
    {
        return "Morning";
    }
    if (_time >= 12 && _time < 16)
    {
        return "Afternoon";
    }
    if (_time >= 16 && _time < 20)
    {
        return "Evening";
    }
    if (_time >= 20 && _time < 24)
    {
        return "Night";
    }
    if (_time >= 24)
    {
        return "Midnight";
    }
};

setStateBasedOnTime = function()
{
    log("Time: Updating shaders for", osmGameData.getDayTime(), getStateNameBasedOnTime());
    state.change(getStateNameBasedOnTime());
};

setWindowSprites = function(arg0 = "night")
{
    var _windowsLayer = layer_get_id("Windows");
    var _bedroomWindow = layer_sprite_get_id(_windowsLayer, "graphic_1D749420");
    var _hallWindow = layer_sprite_get_id(_windowsLayer, "graphic_12D79F33");
    if (arg0 == "night")
    {
        layer_sprite_change(_bedroomWindow, sOutsideBedroomWindowNight);
        layer_sprite_change(_hallWindow, sOutsideHallWindowNight);
    }
    else
    {
        layer_sprite_change(_bedroomWindow, sOutsideBedroomWindowDay);
        layer_sprite_change(_hallWindow, sOutsideHallWindowDay);
    }
};
