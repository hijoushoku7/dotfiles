-- flash.nvim: Neovim 0.13+ compatibility patch
--
-- Neovim PR #39485 (commit 9bfa337, "refactor(globals): SearchState") moved the
-- C globals `search_match_lines` / `search_match_endcol` into a `Search` struct.
-- flash.nvim's lua/flash/hacks.lua still declares the old globals via FFI, so on
-- nvim 0.13-dev every `s` press raises:
--
--   E5108: Lua: .../flash.nvim/lua/flash/hacks.lua:28:
--   <nvim>: undefined symbol: search_match_lines
--   Flash error during redraw: ...
--
-- Upstream fix: https://github.com/folke/flash.nvim/pull/492 (not merged yet).
-- This file monkey-patches the three affected functions in place, keeping the
-- upstream behaviour identical. Delete it once PR #492 lands.
--
-- Refs:
--   https://github.com/folke/flash.nvim/issues/493
--   https://github.com/folke/flash.nvim/issues/495

-- Mirrors SearchState in src/nvim/search_defs.h (linenr_T = int32_t, colnr_T = int).
-- Field order and types must match exactly or the FFI reads garbage.
local SEARCH_STATE_CDEF = [[
  typedef struct {
    bool hl_match;
    int32_t match_lines;
    int match_endcol;
    int32_t first_line;
    int32_t last_line;
    bool no_smartcase;
    int cmdlen;
    bool no_hlsearch;
  } SearchState;

  SearchState Search;
]]

---Resolve the new `Search` symbol, or return nil if this Neovim predates it.
---@return ffi.namespace*|nil
local function search_state()
  local ok, ffi = pcall(require, "ffi")
  if not ok then
    return nil
  end

  -- cdef may fail if something else already declared SearchState; that is fine,
  -- the symbol lookup below is the real capability check.
  pcall(ffi.cdef, SEARCH_STATE_CDEF)

  local resolved = pcall(function()
    return ffi.C.Search.match_lines
  end)
  return resolved and ffi.C or nil
end

local function patch_hacks()
  local C = search_state()
  if not C then
    return -- old Neovim: upstream FFI path still works, leave it alone
  end

  local Hacks = require("flash.hacks")
  local Pos = require("flash.search.pos")

  local incsearch_state = {}

  ---@param from Pos
  function Hacks.get_end_pos(from)
    local ret = Pos({
      from[1] + C.Search.match_lines,
      math.max(0, C.Search.match_endcol - 1),
    })
    local line = vim.api.nvim_buf_get_lines(0, ret[1] - 1, ret[1], false)[1]
    local char_idx = vim.fn.charidx(line, ret[2])
    ret[2] = vim.fn.byteidx(line, char_idx)
    return ret
  end

  function Hacks.save_incsearch_state()
    incsearch_state = {
      match_endcol = C.Search.match_endcol,
      match_lines = C.Search.match_lines,
    }
  end

  function Hacks.restore_incsearch_state()
    C.Search.match_endcol = incsearch_state.match_endcol
    C.Search.match_lines = incsearch_state.match_lines
  end
end

return {
  {
    "folke/flash.nvim",
    config = function(_, opts)
      require("flash").setup(opts)
      local ok, err = pcall(patch_hacks)
      if not ok then
        vim.notify("flash.nvim 0.13 patch failed: " .. tostring(err), vim.log.levels.WARN)
      end
    end,
  },
}
