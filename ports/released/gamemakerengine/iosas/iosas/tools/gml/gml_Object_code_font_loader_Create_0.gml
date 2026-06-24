fontsLoaded = function()
{
    with (code_game_init)
    {
        loadingItemComplete();
    }
};

fontArray = -1;
menuItemArray = localization_get_all_language_names();
menuItemCount = array_length(menuItemArray);
for (var i = 0; i < menuItemCount; i++)
{
    fontArray[i] = font_default;
}
show_debug_message("Loading fonts...");
var romanLabelFont = font_add("NotoSans-Thin.ttf", 14, false, false, 32, 126);
var langKeys = localization_get_all_language_keys();
for (var i = 0; i < menuItemCount; i++)
{
    var key = langKeys[i];
    if (key == "ja" || key == "ko" || key == "zh")
    {
        fontArray[i] = romanLabelFont;
    }
    else
    {
        fontArray[i] = font_load_from_csv(key, "small");
    }
}
show_debug_message("Finished loading fonts.");
fontsLoaded();
