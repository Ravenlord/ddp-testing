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

-- Global iterator for node identifier values.
idIt = 1

-- Global iterator for depth-first tree traversal.
travIt = 1

-- Node class representing binary tree nodes.
Node = {
  -- The node's identifier.
  id = nil,
  -- The node's left child.
  lnode = nil,
  -- The node's right child.
  rnode = nil,
  -- The node's left number assigned during depth-first traversal.
  leftnum = nil,
  -- The node's right number assigned during depth-first traversal.
  rightnum = nil,
  -- The node's path from the root, separated by slashes.
  path = nil,
  -- The node's level.
  level = 0,
  -- The node's parent node.
  parent = nil,
  -- The node's name.
  name = nil
}
Node.__index = Node

--- Node constructor.
-- Returns a new node.
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

--- Create and traverse a complete binary tree.
-- maxlevel determines the height of the tree.
function Node:createTree(maxlevel)
  -- Call the pre-traversal insert hook, used for most tree patterns.
  self:insertPre()

  if self.level < maxlevel then
    -- Create a new left child and its subtree recursively.
    idIt =  idIt + 1
    travIt = travIt + 1
    self.lnode = Node:new(idIt, travIt, self.path .. idIt .. '/', self.level + 1, self, nil)
    self.lnode:createTree(maxlevel)

    -- Create a new right child and its subtree recursively.
    idIt =  idIt + 1
    travIt = travIt + 1
    self.rnode = Node:new(idIt, travIt, self.path .. idIt .. '/', self.level + 1, self, nil)
    self.rnode:createTree(maxlevel)
  end

  -- Assign the right traversal number, since the traversal goes upwards again.
  travIt = travIt + 1
  self.rightnum = travIt

  -- Call the post-traversal insert hook, used only for Nested Sets at this point.
  self:insertPost()
end

--- Pre-traversal insert hook for nodes.
function Node:insertPre()
  -- Dummy implementation.
end

--- Post-traversal insert hook for nodes.
function Node:insertPost()
  -- Dummy implementation.
end

--- Prepare tree test data.
-- Please note: Pre- or post-traversal insert hooks have to be implemented to actually insert nodes.
function prepare_tree()
  -- Configure tree height here, since it should be the same for all tests.
  local treeheight = 10
  -- Create root node manually.
  local root = Node:new(1, 1, 1 .. '/', 1)

  -- Create tree within a transaction to make operation atomic.
  db_query('BEGIN')
  root:createTree(treeheight)
  db_query('COMMIT')
end
