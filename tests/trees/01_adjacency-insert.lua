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
 - Benchmark file for design problem "Trees", "Adjacency List" solution.
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
  local par
  if self.parent == nil then
    par = 'NULL'
  else
    par = self.parent.id
  end
  db_query("INSERT INTO `animals` SET `id` = " .. self.id .. ", `name` = '" .. self.name .. "', `parent_id` = " .. par)
end

--- Prepare data for the benchmark.
--  Is called during the prepare command of sysbench in common.lua.
function prepare_data()
  local query
  query = [[
CREATE TABLE `animals` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `parent_id` INTEGER UNSIGNED,
  CONSTRAINT `fk_animal_parent` FOREIGN KEY (`parent_id`) REFERENCES `animals` (`id`)
)
]]
  db_query(query)

  prepare_tree()

  -- Create ancestor traversal procedure.
  query = [[
CREATE FUNCTION `traverse_ancestors` (`current_animal` INTEGER)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  DECLARE v_anc VARCHAR(255);
  WHILE current_animal IS NOT NULL DO
    SELECT CONCAT_WS(',', v_anc, current_animal) INTO v_anc;
    SELECT `parent_id` INTO current_animal
    FROM `animals`
    WHERE `id` = current_animal;
  END WHILE;
  RETURN v_anc;
END;
]]
  db_query(query)
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the benchmark queries.
-- Is called during the run command of sysbench.
function benchmark()
  db_query('BEGIN')
  rs = db_query("INSERT INTO `animals` (`id`, `name`, `parent_id`) VALUES (2000, 'node-2000', 834)")
  rs = db_query("UPDATE `animals` SET `parent_id` = 2000 WHERE `parent_id` = 834 AND `id` != 2000")
  db_query('ROLLBACK')
end
