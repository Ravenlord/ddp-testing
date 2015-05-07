--[[!
 - This is free and unencumbered software released into the public domain.
 -
 - Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form
 - or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.
 -
 - In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright
 - interest in the software to the public domain. We make this dedication for the benefit of the public at large and to
 - the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in
 - perpetuity of all present and future rights to this software under copyright law.
 -
 - THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 - WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE
 - LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 - OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 -
 - For more information, please refer to <http://unlicense.org/>
--]]

--[[
 - Test data preparation for Trees tests.
 - A complete binary tree of height 10 is created.
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]

idIt = 1
travIt = 1
Node = {
  id = nil,
  lnode = nil,
  rnode = nil,
  leftnum = nil,
  rightnum = nil,
  path = nil,
  level = 0
}
Node.__index = Node
function Node:new(id, leftnum, path, level, parent, o)
  local o = {
    id = nil,
    lnode = nil,
    rnode = nil,
    leftnum = nil,
    rightnum = nil,
    path = nil,
    level = 0,
    parent = nil,
    name = nil
  }
  setmetatable(o, Node)
  o.id = id
  o.leftnum = leftnum
  o.path = path
  o.level = level
  o.parent = parent
  o.name = 'node-' .. o.id
  return o
end

function Node:createTree(maxlevel)
  self:insertPre()
  if self.level < maxlevel then
    idIt =  idIt + 1
    travIt = travIt + 1
    self.lnode = Node:new(idIt, travIt, self.path .. idIt .. '/', self.level + 1, self, nil)
    self.lnode:createTree(maxlevel)

    idIt =  idIt + 1
    travIt = travIt + 1
    self.rnode = Node:new(idIt, travIt, self.path .. idIt .. '/', self.level + 1, self, nil)
    self.rnode:createTree(maxlevel)
  end
  travIt = travIt + 1
  self.rightnum = travIt
  self:insertPost()
end

function Node:insertPre()
end

function Node:insertPost()
end

function prepare_tree()
  local treedepth = 10
  local root = Node:new(1, 1, 1 .. '/', 1)
  db_query('BEGIN')
  root:createTree(treedepth)
  db_query('COMMIT')
end
