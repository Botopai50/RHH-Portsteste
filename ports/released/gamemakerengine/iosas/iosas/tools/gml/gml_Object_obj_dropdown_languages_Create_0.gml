event_inherited();

resetLanguageDropDown = function()
{
    var currentLanguageIndex = (global.language != "en") ? ds_map_find_value(global.localizationMap, "current_language_index") : 0;
    currentHighlightedSubMenuItemIndex = currentLanguageIndex;
    displayItem = menuItemArray[currentLanguageIndex];
};

menuItemArray = localization_get_all_language_names();
menuItemLanguageKeys = localization_get_all_language_keys();
menuItemCount = array_length(menuItemArray);
for (var i = 0; i < menuItemCount; i++)
{
    switch (menuItemLanguageKeys[i])
    {
        case "ja":
            menuItemArray[i] = "Japanese";
            break;
        case "ko":
            menuItemArray[i] = "Korean";
            break;
        case "zh":
            menuItemArray[i] = "Chinese";
            break;
    }
}
menuItemFontArray = global.fontLoader.fontArray;
resetLanguageDropDown();
expandWidthWhenOpened = false;
inputDelay = false;
loadingMessage = -4;
langChangeKey = undefined;
loading = false;
alarmLoadFonts = 2;
