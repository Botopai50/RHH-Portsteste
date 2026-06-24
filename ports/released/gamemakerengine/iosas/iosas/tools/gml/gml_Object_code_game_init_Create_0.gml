gameStart = function()
{
    game_init();
    window_set_size(global.windowWidth, global.windowHeight);
    global.optionsController = instance_create_layer(0, 0, "system_layer", code_players_customizations_controller);
    instance_create_layer(0, 0, "system_layer", obj_music_controller);
    if (global.precompileSweep)
    {
        global.devToolRoomSweeper = instance_create_layer(0, 0, "system_layer", obj_precompile_tool_room_sweeper);
    }
};

loadingItemComplete = function()
{
    loadingCompletedItems++;
    if (loadingCompletedItems >= loadingItemCount)
    {
        alarm[1] = 1;
    }
};

var startDelay = 60;
alarm[0] = startDelay;
loadingItemCount = 2;
loadingCompletedItems = 0;
loadingTextXPos = room_width / 2;
loadingTextYPos = room_height / 2;
x = loadingTextXPos - 8;
y = loadingTextYPos - 24;
image_speed = 0.25;

ini_open("config.ini");
global.IdolSFX = ini_read_real("Performance", "IdolSFX", 1);
ini_close();
global.mandalaRedrawAccum = 100000;
