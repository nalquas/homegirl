module lua_api.image;

import std.string;
import std.conv;
import riverd.lua;
import riverd.lua.types;

import machine;
import program;
import pixmap;

/**
  register image functions for a lua program
*/
void registerFunctions(Program program)
{
  auto lua = program.lua;
  luaL_dostring(lua, "image = {}");

  /// image.new(width, height, colorbits): img
  extern (C) int image_new(lua_State* L) @trusted
  {
    const width = lua_tonumber(L, 1);
    const height = lua_tonumber(L, 2);
    const colorBits = lua_tointeger(L, 3);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      lua_pushinteger(L, prog.createPixmap(cast(uint) width, cast(uint) height,
          cast(ubyte) colorBits));
      return 1;
    }
    catch (Exception err)
    {
      luaL_error(L, toStringz(err.msg));
      return 0;
    }
  }

  lua_register(lua, "_", &image_new);
  luaL_dostring(lua, "image.new = _");

  /// image.load(filename[, maxframes]): img[]
  extern (C) int image_load(lua_State* L) @trusted
  {
    const filename = to!string(lua_tostring(L, 1));
    auto maxframes = lua_tonumber(L, 2);
    const maxset = 1 - lua_isnoneornil(L, 2);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (!prog.isOnOriginDrive(filename) && !prog.hasPermission(Permissions.readOtherDrives))
        throw new Exception("no permission to read other drives!");
      if (!maxset)
        maxframes = -1;
      uint[] anim = prog.loadAnimation(prog.actualFile(filename), cast(uint) maxframes);
      lua_createtable(L, cast(uint) anim.length, 0);
      for (uint i = 0; i < anim.length; i++)
      {
        lua_pushinteger(L, anim[i]);
        lua_rawseti(L, -2, i + 1);
      }
      return 1;
    }
    catch (Exception err)
    {
      lua_pushnil(L);
      return 1;
    }
  }

  lua_register(lua, "_", &image_load);
  luaL_dostring(lua, "image.load = _");

  /// image.save(filename, img[]): success
  extern (C) int image_save(lua_State* L) @trusted
  {
    const filename = to!string(lua_tostring(L, 1));
    const anim_len = lua_rawlen(L, 2);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (!prog.isOnOriginDrive(filename) && !prog.hasPermission(Permissions.readOtherDrives))
        throw new Exception("no permission to read other drives!");
      uint[] anim;
      if (anim_len)
      {
        lua_pushnil(L);
        while (lua_next(L, 2))
        {
          anim ~= cast(uint) lua_tointeger(L, -1);
          lua_pop(L, 1);
        }
      }
      prog.saveAnimation(prog.actualFile(filename), anim);
      lua_pushboolean(L, true);
      return 1;
    }
    catch (Exception err)
    {
      lua_pushboolean(L, false);
      return 1;
    }
  }

  lua_register(lua, "_", &image_save);
  luaL_dostring(lua, "image.save = _");

  /// image.size(img): width, height
  extern (C) int image_size(lua_State* L) @trusted
  {
    const imgID = lua_tointeger(L, 1);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (imgID >= prog.pixmaps.length || !prog.pixmaps[cast(uint) imgID])
        throw new Exception("Invalid image!");
      lua_pushinteger(L, prog.pixmaps[cast(uint) imgID].width);
      lua_pushinteger(L, prog.pixmaps[cast(uint) imgID].height);
      return 2;
    }
    catch (Exception err)
    {
      luaL_error(L, toStringz(err.msg));
      return 0;
    }
  }

  lua_register(lua, "_", &image_size);
  luaL_dostring(lua, "image.size = _");

  /// image.duration(img[, milliseconds]): milliseconds
  extern (C) int image_duration(lua_State* L) @trusted
  {
    const imgID = lua_tointeger(L, 1);
    const duration = lua_tonumber(L, 2);
    const set = 1 - lua_isnoneornil(L, 2);

    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (imgID >= prog.pixmaps.length || !prog.pixmaps[cast(uint) imgID])
        throw new Exception("Invalid image!");
      if (set)
        prog.pixmaps[cast(uint) imgID].duration = cast(uint) duration;
      lua_pushinteger(L, prog.pixmaps[cast(uint) imgID].duration);
      return 1;
    }
    catch (Exception err)
    {
      luaL_error(L, toStringz(err.msg));
      return 0;
    }
  }

  lua_register(lua, "_", &image_duration);
  luaL_dostring(lua, "image.duration = _");

  /// image.copymode([mode]): mode
  extern (C) int image_copymode(lua_State* L) @trusted
  {
    const mode = lua_tointeger(L, 1);
    const set = 1 - lua_isnoneornil(L, 1);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (!prog.activeViewport)
        throw new Exception("No active viewport!");
      if (set)
        prog.activeViewport.pixmap.copymode = cast(CopyMode) mode;
      lua_pushinteger(L, prog.activeViewport.pixmap.copymode);
      return 1;
    }
    catch (Exception err)
    {
      luaL_error(L, toStringz(err.msg));
      return 0;
    }
  }

  lua_register(lua, "_", &image_copymode);
  luaL_dostring(lua, "image.copymode = _");

  /// image.tri(img, x1,y1, x2,y2, x3,y3, imgx1,imgy1, imgx2,imgy2, imgx3,imgy3)
  extern (C) int image_tri(lua_State* L) @trusted
  {
    const imgID = lua_tointeger(L, 1);
    const x1 = lua_tonumber(L, 2);
    const y1 = lua_tonumber(L, 3);
    const x2 = lua_tonumber(L, 4);
    const y2 = lua_tonumber(L, 5);
    const x3 = lua_tonumber(L, 6);
    const y3 = lua_tonumber(L, 7);
    const imgx1 = lua_tonumber(L, 8);
    const imgy1 = lua_tonumber(L, 9);
    const imgx2 = lua_tonumber(L, 10);
    const imgy2 = lua_tonumber(L, 11);
    const imgx3 = lua_tonumber(L, 12);
    const imgy3 = lua_tonumber(L, 13);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (!prog.activeViewport)
        throw new Exception("No active viewport!");
      if (imgID >= prog.pixmaps.length || !prog.pixmaps[cast(uint) imgID])
        throw new Exception("Invalid image!");
      prog.activeViewport.pixmap.copyTriFrom(prog.pixmaps[cast(uint) imgID],
          imgx1, imgy1, imgx2, imgy2, imgx3, imgy3, x1, y1, x2, y2, x3, y3);
      return 0;
    }
    catch (Exception err)
    {
      luaL_error(L, toStringz(err.msg));
      return 0;
    }
  }

  lua_register(lua, "_", &image_tri);
  luaL_dostring(lua, "image.tri = _");

  /// image.draw(img, x, y, imgx, imgy, width, height[, imgwidth, imgheight])
  extern (C) int image_draw(lua_State* L) @trusted
  {
    const imgID = lua_tointeger(L, 1);
    auto x = lua_tonumber(L, 2);
    auto y = lua_tonumber(L, 3);
    auto imgx = lua_tonumber(L, 4);
    auto imgy = lua_tonumber(L, 5);
    auto width = lua_tonumber(L, 6);
    auto height = lua_tonumber(L, 7);
    auto imgwidth = lua_tonumber(L, 8);
    auto imgheight = lua_tonumber(L, 9);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (!prog.activeViewport)
        throw new Exception("No active viewport!");
      if (imgID >= prog.pixmaps.length || !prog.pixmaps[cast(uint) imgID])
        throw new Exception("Invalid image!");
      if (imgwidth == 0)
        imgwidth = width;
      if (imgheight == 0)
        imgheight = height;
      if (width < 0)
      {
        x += width;
        width *= -1;
        imgx += imgwidth;
        imgwidth *= -1;
      }
      if (height < 0)
      {
        y += height;
        height *= -1;
        imgy += imgheight;
        imgheight *= -1;
      }
      float scaleX = imgwidth / width;
      float scaleY = imgheight / height;
      if (scaleX < 0)
        imgx--;
      if (scaleY < 0)
        imgy--;
      prog.activeViewport.pixmap.copyFrom(prog.pixmaps[cast(uint) imgID],
          cast(int) imgx, cast(int) imgy, cast(int) x, cast(int) y,
          cast(uint) width, cast(uint) height, scaleX, scaleY);
      return 0;
    }
    catch (Exception err)
    {
      luaL_error(L, toStringz(err.msg));
      return 0;
    }
  }

  lua_register(lua, "_", &image_draw);
  luaL_dostring(lua, "image.draw = _");

  /// image.copy(img, x, y, imgx, imgy, width, height)
  extern (C) int image_copy(lua_State* L) @trusted
  {
    const imgID = lua_tonumber(L, 1);
    const x = lua_tonumber(L, 2);
    const y = lua_tonumber(L, 3);
    const imgx = lua_tonumber(L, 4);
    const imgy = lua_tonumber(L, 5);
    const width = lua_tonumber(L, 6);
    const height = lua_tonumber(L, 7);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (!prog.activeViewport)
        throw new Exception("No active viewport!");
      if (imgID >= prog.pixmaps.length || !prog.pixmaps[cast(uint) imgID])
        throw new Exception("Invalid image!");
      prog.pixmaps[cast(uint) imgID].copyFrom(prog.activeViewport.pixmap,
          cast(int) x, cast(int) y, cast(int) imgx, cast(int) imgy,
          cast(uint) width, cast(uint) height);
      return 0;
    }
    catch (Exception err)
    {
      luaL_error(L, toStringz(err.msg));
      return 0;
    }
  }

  lua_register(lua, "_", &image_copy);
  luaL_dostring(lua, "image.copy = _");

  /// image.usepalette(img)
  extern (C) int image_usepalette(lua_State* L) @trusted
  {
    const imgID = lua_tointeger(L, 1);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (!prog.activeViewport)
        throw new Exception("No active viewport!");
      if (imgID >= prog.pixmaps.length || !prog.pixmaps[cast(uint) imgID])
        throw new Exception("Invalid image!");
      prog.activeViewport.pixmap.copyPaletteFrom(prog.pixmaps[cast(uint) imgID]);
      return 0;
    }
    catch (Exception err)
    {
      luaL_error(L, toStringz(err.msg));
      return 0;
    }
  }

  lua_register(lua, "_", &image_usepalette);
  luaL_dostring(lua, "image.usepalette = _");

  /// image.copypalette(img)
  extern (C) int image_copypalette(lua_State* L) @trusted
  {
    const imgID = lua_tointeger(L, 1);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (!prog.activeViewport)
        throw new Exception("No active viewport!");
      if (imgID >= prog.pixmaps.length || !prog.pixmaps[cast(uint) imgID])
        throw new Exception("Invalid image!");
      prog.pixmaps[cast(uint) imgID].copyPaletteFrom(prog.activeViewport.pixmap);
      return 0;
    }
    catch (Exception err)
    {
      luaL_error(L, toStringz(err.msg));
      return 0;
    }
  }

  lua_register(lua, "_", &image_copypalette);
  luaL_dostring(lua, "image.copypalette = _");

  /// image.forget(img)
  extern (C) int image_forget(lua_State* L) @trusted
  {
    const imgID = lua_tointeger(L, 1);
    lua_getglobal(L, "__program");
    auto prog = cast(Program*) lua_touserdata(L, -1);
    try
    {
      if (imgID >= prog.pixmaps.length || !prog.pixmaps[cast(uint) imgID])
        throw new Exception("Invalid image!");
      prog.removePixmap(cast(uint) imgID);
      return 0;
    }
    catch (Exception err)
    {
      luaL_error(L, toStringz(err.msg));
      return 0;
    }
  }

  lua_register(lua, "_", &image_forget);
  luaL_dostring(lua, "image.forget = _");
}
