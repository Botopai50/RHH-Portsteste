function UIMenu() constructor
{
    position = 0;
    elements = [];
    style = "text";
    
    scroll = function(arg0)
    {
        audio_play_sound(fxScroll, 1, false);
        position += arg0;
        if (position >= array_length(elements))
        {
            position = 0;
        }
        if (position < 0)
        {
            position = array_length(elements) - 1;
        }
    };
    
    draw = function(arg0, arg1, arg2)
    {
        for (var _i = 0; _i <= (array_length(elements) - 1); _i++)
        {
            elements[_i].draw(arg0, arg1 + (arg2 * _i), _i == position, style);
        }
    };
    
    select = function()
    {
        audio_play_sound(fxSelect, 1, false);
        elements[position].onSelect();
    };
    
    changeValue = function(arg0)
    {
        elements[position].changeValue(arg0);
    };
    
    addButton = function(arg0, arg1, arg2 = "ui", arg3 = 170)
    {
        array_push(elements, new UIButtonWidget(arg0, arg1, arg2, arg3));
        return self;
    };
    
    addCheckbox = function(arg0, arg1, arg2 = false)
    {
        array_push(elements, new UICheckboxWidget(arg0, arg1, arg2));
        return self;
    };
    
    addSlider = function(arg0, arg1, arg2 = 10)
    {
        array_push(elements, new UISliderWidget(arg0, arg1, arg2));
        return self;
    };
    
    addHorizontalButtons = function(arg0)
    {
        array_push(elements, arg0);
        return self;
    };
    
    setStyle = function(arg0)
    {
        style = arg0;
        return self;
    };
}

function UIWidget(arg0 = function()
{
}, arg1 = function()
{
}) constructor
{
    onSelect = arg0;
    value = 0;
    
    changeValue = function()
    {
    };
    
    onValueChange = arg1;
}

function UIButtonWidget(arg0 = "", arg1, arg2, arg3 = 170) : UIWidget(arg1) constructor
{
    text = arg0;
    fontName = arg2;
    wrap = arg3;
    __scSel = -1;
    __scEl = undefined;
    __locStr = undefined;

    draw = function(arg0, arg1, arg2, arg3)
    {
        if (arg3 == "text")
        {
            method_call(drawStyleText, [arg0, arg1, arg2]);
        }
        if (arg3 == "button")
        {
            method_call(drawStyleButton, [arg0, arg1, arg2]);
        }
    };

    drawStyleText = function(arg0, arg1, arg2)
    {
        var _icon = arg2 ? sUIChoiceArrowSelected : sUIChoiceArrowUnselected;
        if (__scEl == undefined || __scSel != arg2)
        {
            fontName = (fontName == "ui") ? getFontName("ui") : fontName;
            if (__locStr == undefined)
                __locStr = lexicon_text(text);
            var _color = arg2 ? 15909607 : 16777215;
            __scEl = scribble(__locStr, "uimenu_" + __locStr).starting_format(fontName, _color).wrap(wrap).line_spacing("70%").align(1);
            __scSel = arg2;
        }
        __scEl.draw(arg0, arg1);
        draw_sprite(_icon, 0, __scEl.get_left(arg0) - 14, arg1);
    };

    drawStyleButton = function(arg0, arg1, arg2)
    {
        var _color = arg2 ? 16777215 : 4207654;
        var _sc = scribble(lexicon_text(text)).wrap(200).starting_format(getFontName("ui"), _color);
        arg1 -= 16;
        arg0 -= 8;
        var _buttonSprite = arg2 ? sUIJournalPostItButtonHover : sUIJournalPostItButton;
        draw_sprite_stretched(_buttonSprite, -1, arg0, arg1, _sc.get_width() + 28, _sc.get_height() + 24);
        _sc.draw(arg0 + 8, arg1 + 9);
    };
}

function UIHorizontalButtons() : UIWidget() constructor
{
    position = 0;
    elements = [];
    
    scroll = function(arg0)
    {
        position += arg0;
        audio_play_sound(fxScroll, 1, false);
        if (position >= array_length(elements))
        {
            position = 0;
        }
        if (position < 0)
        {
            position = array_length(elements) - 1;
        }
    };
    
    changeValue = function(arg0)
    {
        scroll(arg0);
    };
    
    onSelect = function()
    {
        elements[position].onSelect();
    };
    
    draw = function(arg0, arg1, arg2, arg3)
    {
        var _spacing = 32;
        var _width = _spacing * (array_length(elements) - 1);
        var _startX = arg0 - (_width / 2);
        for (var _i = 0; _i <= (array_length(elements) - 1); _i++)
        {
            var _sel = arg2 ? (_i == position) : false;
            elements[_i].draw(_startX + (_spacing * _i), arg1, _sel, arg3);
        }
    };
    
    addButton = function(arg0, arg1)
    {
        array_push(elements, new UIButtonWidget(arg0, arg1));
        return self;
    };
}

function UICheckboxWidget(arg0 = "", arg1 = function()
{
}, arg2 = false) : UIWidget() constructor
{
    text = arg0;
    checked = arg2;
    onChange = arg1;
    __scSel = -1;

    draw = function(arg0, arg1, arg2, arg3)
    {
        if (arg3 == "text")
        {
            method_call(drawStyleText, [arg0, arg1, arg2]);
        }
        if (arg3 == "button")
        {
            method_call(drawStyleButton, [arg0, arg1, arg2]);
        }
    };

    drawStyleText = function(arg0, arg1, arg2)
    {
        var _icon = arg2 ? sUIChoiceArrowSelected : sUIChoiceArrowUnselected;
        var _checkedSprite = checked ? sUISettingsCheckTick : sUISettingsCheckEmpty;
        var _sc = scribble(lexicon_text(text));
        if (__scSel != arg2)
        {
            var _color = arg2 ? 15909607 : 16777215;
            _sc.starting_format(getFontName("ui"), _color).align(1);
            __scSel = arg2;
        }
        var _width = _sc.get_width();
        draw_sprite(_checkedSprite, -1, arg0 + (_width / 2) + 6, arg1 - 4);
        _sc.draw(arg0, arg1);
        draw_sprite(_icon, 0, _sc.get_left(arg0) - 14, arg1);
    };
    
    drawStyleButton = function(arg0, arg1, arg2)
    {
        var _color = arg2 ? 12539538 : 0;
        var _icon = arg2 ? sUIChoiceArrowSelected : sUIChoiceArrowUnselected;
        var _checkedSprite = checked ? sUIJournalCheckTick : sUIJournalCheckEmpty;
        var _sc = scribble(lexicon_text(text)).starting_format(getFontName("ui"), _color);
        _sc.draw(arg0, arg1);
        var _width = _sc.get_width();
        draw_sprite(_checkedSprite, -1, arg0 + _width + 12, arg1 - 4);
        draw_sprite(_icon, 0, _sc.get_left(arg0) - 14, arg1);
    };
    
    onSelect = function()
    {
        checked = checked ? false : true;
        onChange(checked);
    };
}

function UISliderWidget(arg0 = "", arg1 = function()
{
}, arg2 = 10) : UIWidget() constructor
{
    text = arg0;
    value = arg2;
    onChange = arg1;
    position = 0;
    __scSel = -1;
    __scVal = -999;

    draw = function(arg0, arg1, arg2, arg3)
    {
        if (arg3 == "text")
        {
            method_call(drawStyleText, [arg0, arg1, arg2]);
        }
        if (arg3 == "button")
        {
            method_call(drawStyleButton, [arg0, arg1, arg2]);
        }
    };

    drawStyleText = function(arg0, arg1, arg2)
    {
        var _icon = arg2 ? sUIChoiceArrowSelected : sUIChoiceArrowUnselected;
        var _sc = scribble(lexicon_text(text) + "\n" + getValueText());
        if (__scSel != arg2 || __scVal != value)
        {
            var _color = arg2 ? 15909607 : 16777215;
            _sc.starting_format(getFontName("ui"), _color).align(1);
            __scSel = arg2;
            __scVal = value;
        }
        _sc.draw(arg0, arg1);
        draw_sprite(_icon, 0, _sc.get_left(arg0) - 14, arg1);
    };
    
    drawStyleButton = function(arg0, arg1, arg2)
    {
        var _color = arg2 ? 12539538 : 0;
        var _icon = arg2 ? sUIChoiceArrowSelected : sUIChoiceArrowUnselected;
        var _sc = scribble(lexicon_text(text)).starting_format(getFontName("ui"), _color);
        _sc.draw(arg0, arg1);
        var _sliderX = arg0;
        var _sliderY = arg1 + 16;
        draw_sprite(sUIJournalSliderArrow, -1, _sliderX - 8, _sliderY);
        for (var _i = 0; _i < 10; _i++)
        {
            var _sprite = (_i < value) ? sUIJournalSliderFull : sUIJournalSliderEmpty;
            draw_sprite(_sprite, -1, _sliderX, _sliderY);
            _sliderX += 16;
        }
        draw_sprite_ext(sUIJournalSliderArrow, -1, _sliderX + 4, _sliderY, -1, 1, 0, c_white, 1);
        draw_sprite(_icon, 0, _sc.get_left(arg0) - 14, arg1);
    };
    
    getValueText = function()
    {
        var _text = "";
        for (var _i = 0; _i <= 10; _i++)
        {
            _text += ((_i == value) ? "+" : "-");
        }
        return _text;
    };
    
    changeValue = function(arg0)
    {
        value += arg0;
        value = clamp(value, 0, 10);
        onChange(value);
    };
    
    onSelect = function()
    {
    };
}
