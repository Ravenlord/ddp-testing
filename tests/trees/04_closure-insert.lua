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
 - Benchmark file for design problem "Trees", "Closure Table" solution.
 - Insert intermediate node "node-2000" (id 2000) between "node-834" and its children.
 - (id: 834, name: node-834, parent: 770, path: 1/513/769/770/834/, lnum: 166300, rnum: 178800, level 5).
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "../common.inc")
dofile(pathtest .. "prepare.inc")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions


--- Implement the appropriate insert function.
-- Is called during tree traversal in prepare_tree().
function Node:insertPre()
  local query
  db_query("INSERT INTO `animals` SET `id` = " .. self.id .. ", `name` = '" .. self.name .. "'")
  if self.parent == nil then
    db_query('INSERT INTO `tree_paths` SET `ancestor` = ' .. self.id .. ', `descendant` = ' .. self.id .. ', `path_length` = 0')
  else
    query = [[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
  SELECT `ancestor`, ]] .. self.id .. [[, `path_length` + 1
  FROM `tree_paths`
  WHERE `descendant` = ]] .. self.parent.id .. [[
  UNION ALL
  SELECT ]] .. self.id .. [[, ]] .. self.id .. [[, 0
]]
    db_query(query)
  end
end

--- Prepare data for the benchmark.
--  Is called during the prepare command of sysbench in common.lua.
function prepare_data()
  local query
  query = [[
CREATE TABLE `animals` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL
)
]]
  db_query(query)
  query = [[
CREATE TABLE `tree_paths` (
  `ancestor` INTEGER UNSIGNED NOT NULL,
  `descendant` INTEGER UNSIGNED NOT NULL,
  `path_length` INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (`ancestor`, `descendant`),
  CONSTRAINT `fk_tree_ancestor` FOREIGN KEY (`ancestor`) REFERENCES `animals` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_tree_descendant` FOREIGN KEY (`descendant`) REFERENCES `animals` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  INDEX(`descendant`),
  INDEX(`path_length`)
)
]]
  db_query(query)

  prepare_tree()
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the benchmark queries.
-- Is called during the run command of sysbench.
function benchmark()
  db_query('BEGIN')
  rs = db_query("INSERT INTO `animals` (`id`, `name`) VALUES (2000, 'node-2000')")
  rs = db_query("UPDATE `tree_paths` SET `path_length` = `path_length` + 1 WHERE `ancestor` = 834 AND `descendant` != 834")
  rs = db_query([[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
    SELECT `ancestor`, 2000, `path_length` + 1
    FROM `tree_paths`
    WHERE `descendant` = 834
  UNION ALL
    SELECT 2000, `descendant`, `path_length` - 1
    FROM `tree_paths`
    WHERE `ancestor` = 834 AND `descendant` != 834
  UNION ALL
    SELECT 2000, 2000, 0
]])
  db_query('ROLLBACK')
end
