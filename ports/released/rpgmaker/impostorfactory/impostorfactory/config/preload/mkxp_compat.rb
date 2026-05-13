# mkxp-freebird → mkxp-z compatibility shim.
#
# The Freebird game scripts (and the preload scripts that ship with
# them) were authored against Ancurio/mkxp-freebird. mkxp-z renamed or
# omitted a handful of methods. This file is a one-shot patch covering
# the full known Freebird-specific surface so the game stops surfacing
# NoMethodErrors one at a time.

# --------------------------------------------------------------------
# MKXP module: mkxp-freebird's util namespace. mkxp-z calls the same
# surface `System`. Stub the two methods System is missing, then alias
# MKXP -> System so MKXP.* calls in the game and in win32_wrap.rb work.
# --------------------------------------------------------------------
if defined?(System)
  unless System.respond_to?(:mouse_in_window)
    def System.mouse_in_window
      # Return false on the handheld so the game's Mouse module skips
      # its cursor-render + hit-test path entirely. Real input flows
      # through the controller via SDL; no point drawing a stuck
      # software cursor at (0,0).
      false
    end
  end

  unless System.respond_to?(:raw_key_states)
    def System.raw_key_states
      # win32_wrap.rb mutates this buffer via setbyte, so return a fresh
      # zeroed copy each call. Real input flows through SDL/mkxp-z.
      "\x00" * 256
    end
  end
end

unless defined?(MKXP)
  MKXP = defined?(System) ? System : Module.new
end

# --------------------------------------------------------------------
# Kernel additions: mkxp-freebird defines these as top-level functions
# (via rb_mKernel). The game and translator scripts call them
# unqualified, so they need to live on Kernel.
# --------------------------------------------------------------------

# Forward to mkxp-z's native System.default_font_family= when available;
# fall back to RGSS Font.default_name= otherwise.
unless Kernel.respond_to?(:_mkxp_set_default_font_family)
  module Kernel
    def _mkxp_set_default_font_family(family)
      if defined?(System) && System.respond_to?(:default_font_family=)
        System.default_font_family = family
      elsif defined?(Font)
        Font.default_name = family
      end
    end
  end
end

# Steam achievements aren't wired up on a handheld build; swallow calls.
unless Kernel.respond_to?(:_steam_achievement_unlock)
  module Kernel
    def _steam_achievement_unlock(*_args); end
  end
end

# --------------------------------------------------------------------
# Pin aspect-ratio stretching on. mkxp.json's `fixedAspectRatio: false`
# is only the initial state — the game's Options.start applies a stored
# preference (default: keep aspect) that re-letterboxes the screen.
# Override the setter so the game can't re-enable letterboxing.
# --------------------------------------------------------------------
if defined?(Graphics) && Graphics.respond_to?(:fixed_aspect_ratio=) && \
   !Graphics.respond_to?(:__mkxpz_orig_fixed_aspect_set)
  Graphics.singleton_class.send(:alias_method, :__mkxpz_orig_fixed_aspect_set, :fixed_aspect_ratio=)
  Graphics.define_singleton_method(:fixed_aspect_ratio=) do |_value|
    Graphics.send(:__mkxpz_orig_fixed_aspect_set, false)
  end
end

# --------------------------------------------------------------------
# Hide the cursor. With no real mouse on the handheld it just sits at
# (0,0) as a top-left blob. The game (and win32_wrap.rb's ShowCursor)
# may flip Graphics.show_cursor on; force it off.
# --------------------------------------------------------------------
if defined?(Graphics) && Graphics.respond_to?(:show_cursor=) && \
   !Graphics.respond_to?(:__mkxpz_orig_show_cursor_set)
  Graphics.singleton_class.send(:alias_method, :__mkxpz_orig_show_cursor_set, :show_cursor=)
  Graphics.define_singleton_method(:show_cursor=) do |_value|
    Graphics.send(:__mkxpz_orig_show_cursor_set, false)
  end
  Graphics.show_cursor = false
end

# --------------------------------------------------------------------
# Graphics type-shape changes between forks. mkxp-freebird's
# `smooth_scaling` was a bool; mkxp-z made it a fixnum (0..4 = nearest
# / bilinear / bicubic / lanczos3 / xBRZ). Bridge both directions so
# the game's options menu can pass true/false and read it back via
# truthiness checks.
# --------------------------------------------------------------------
if defined?(Graphics) && Graphics.respond_to?(:smooth_scaling=) && \
   !Graphics.respond_to?(:__mkxpz_orig_smooth_scaling_set)
  Graphics.singleton_class.send(:alias_method, :__mkxpz_orig_smooth_scaling_set, :smooth_scaling=)
  Graphics.singleton_class.send(:alias_method, :__mkxpz_orig_smooth_scaling_get, :smooth_scaling)

  Graphics.define_singleton_method(:smooth_scaling=) do |value|
    value = (value ? 1 : 0) if value == true || value == false
    Graphics.send(:__mkxpz_orig_smooth_scaling_set, value)
  end

  Graphics.define_singleton_method(:smooth_scaling) do
    val = Graphics.send(:__mkxpz_orig_smooth_scaling_get)
    val.is_a?(Integer) ? (val != 0) : val
  end
end
