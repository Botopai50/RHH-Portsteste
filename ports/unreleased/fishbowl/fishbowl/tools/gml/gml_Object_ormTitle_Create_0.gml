state = new SnowState("Init");
logStateChange(state);
store = {};
state.add("Init", 
{
    enter: function()
    {
        osmAudio.atmosState.play(lpRain);
        osmAudio.musicState.play(lpMainMenu);
        osmAudio.stopAllFXLoops();
        osmPPFX.state.change("Title");
    },
    
    step: function()
    {
        makeRainParticle("rainDrop2", oParticleRainFall);
        makeRainParticle("rainDrop2", oParticleRainDrop);
        makeRainParticle("rainDrop2", oParticleRainDrop2);
        makeRainParticle("rainDrop2", oParticleRainDrop3);
        state.change("StartScreen");
    },
    
    pause: function()
    {
    },
    
    unpause: function()
    {
    }
});
state.add("StartScreen", 
{
    enter: function()
    {
    },
    
    step: function()
    {
        if (inputproxy_check_released("action"))
        {
            state.change("Ready");
        }
    }
});
state.add("Ready", 
{
    enter: function()
    {
        var _yOffset = 20;
        store.cenX = camera_get_view_x(view_camera[0]) + (camera_get_view_width(view_camera[0]) / 2);
        store.cenY = camera_get_view_y(view_camera[0]) + (camera_get_view_height(view_camera[0]) / 2) + _yOffset;
        store.menu = new UIMenu();
        if (osmGameData.getSaveDataExists())
        {
            store.menu.addButton("menu.title.continue", function()
            {
                state.change("Waiting");
                osmGameState.state.continueGame();
            });
        }
        store.menu.addButton("menu.title.newgame", function()
        {
            state.change("Waiting");
            if (osmGameData.getSaveDataExists())
            {
                osmGameState.state.confirmNewGame();
            }
            else
            {
                osmGameState.state.startGame();
            }
        });
        store.menu.addButton("menu.title.settings", function()
        {
            state.change("Waiting");
            osmGameState.state.change("Settings");
        });
        store.menu.addButton("menu.title.credits", function()
        {
            state.change("Waiting");
            osmGameState.state.change("Credits");
        });
        store.menu.addButton("menu.title.feedback", function()
        {
            url_open("https://discord.gg/n5gaXVgDbU");
        }, "ui", 300).addButton("menu.title.quit", function()
        {
            state.change("Waiting");
            osmGameState.state.confirmQuitGame();
        });
    },
    
    draw: function()
    {
        drawMenu();
    },
    
    step: function()
    {
        if (inputproxy_check_released("action"))
        {
            store.menu.select();
        }
        if (inputproxy_check_released("up"))
        {
            store.menu.scroll(-1);
        }
        if (inputproxy_check_released("down"))
        {
            store.menu.scroll(1);
        }
        if (inputproxy_check_released("left"))
        {
            store.menu.changeValue(-1);
        }
        if (inputproxy_check_released("right"))
        {
            store.menu.changeValue(1);
        }
        if (oTitleFishbowl.y > 350)
        {
            oTitleFishbowl.y -= oTitleFishbowl.y / 170;
        }
    }
});
state.add("Waiting", 
{
    draw: function()
    {
        drawMenu();
    }
});

drawMenu = function()
{
    var _menuYOffset = 43;
    var _scale = 2;
    var _cx = store.cenX;
    var _cy = store.cenY - _menuYOffset;
    var _prev = matrix_get(matrix_world);
    matrix_set(matrix_world, matrix_build(_cx, _cy, 0, 0, 0, 0, _scale, _scale, 1));
    store.menu.draw(0, 0, 15);
    matrix_set(matrix_world, _prev);
};

makeRainParticle = function(arg0, arg1)
{
    variable_struct_set(store, arg0, instance_create_layer(0, 0, "Weather", arg1));
    variable_struct_get(store, arg0).state.init();
    variable_struct_get(store, arg0).state.start();
};

