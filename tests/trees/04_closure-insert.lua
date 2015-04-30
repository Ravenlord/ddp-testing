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
 - Insert intermediate node "four-legged" between "carnivore" and its children.
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "../common.inc")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions


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
    ON UPDATE CASCADE
)
]]
  db_query(query)

  db_query("INSERT INTO `animals` SET `name` = 'carnivore'")
  db_query('INSERT INTO `tree_paths` SET `ancestor` = LAST_INSERT_ID(), `descendant` = LAST_INSERT_ID(), `path_length` = 0')

  db_query("INSERT INTO `animals` SET `name` = 'feline'")
  query = [[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
  SELECT `ancestor`, LAST_INSERT_ID(), `path_length` + 1
  FROM `tree_paths`
  WHERE `descendant` = 1
  UNION ALL
  SELECT LAST_INSERT_ID(), LAST_INSERT_ID(), 0
]]
  db_query(query)

  db_query("INSERT INTO `animals` SET `name` = 'cat'")
  query = [[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
  SELECT `ancestor`, LAST_INSERT_ID(), `path_length` + 1
  FROM `tree_paths`
  WHERE `descendant` = 2
  UNION ALL
  SELECT LAST_INSERT_ID(), LAST_INSERT_ID(), 0
]]
  db_query(query)

  db_query("INSERT INTO `animals` SET `name` = 'big cat'")
  query = [[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
  SELECT `ancestor`, LAST_INSERT_ID(), `path_length` + 1
  FROM `tree_paths`
  WHERE `descendant` = 2
  UNION ALL
  SELECT LAST_INSERT_ID(), LAST_INSERT_ID(), 0
]]
  db_query(query)

  db_query("INSERT INTO `animals` SET `name` = 'tiger'")
  query = [[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
  SELECT `ancestor`, LAST_INSERT_ID(), `path_length` + 1
  FROM `tree_paths`
  WHERE `descendant` = 4
  UNION ALL
  SELECT LAST_INSERT_ID(), LAST_INSERT_ID(), 0
]]
  db_query(query)

  db_query("INSERT INTO `animals` SET `name` = 'lion'")
  query = [[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
  SELECT `ancestor`, LAST_INSERT_ID(), `path_length` + 1
  FROM `tree_paths`
  WHERE `descendant` = 4
  UNION ALL
  SELECT LAST_INSERT_ID(), LAST_INSERT_ID(), 0
]]
  db_query(query)

  db_query("INSERT INTO `animals` SET `name` = 'canine'")
  query = [[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
  SELECT `ancestor`, LAST_INSERT_ID(), `path_length` + 1
  FROM `tree_paths`
  WHERE `descendant` = 1
  UNION ALL
  SELECT LAST_INSERT_ID(), LAST_INSERT_ID(), 0
]]
  db_query(query)

  db_query("INSERT INTO `animals` SET `name` = 'dog'")
  query = [[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
  SELECT `ancestor`, LAST_INSERT_ID(), `path_length` + 1
  FROM `tree_paths`
  WHERE `descendant` = 7
  UNION ALL
  SELECT LAST_INSERT_ID(), LAST_INSERT_ID(), 0
]]
  db_query(query)

  db_query("INSERT INTO `animals` SET `name` = 'wolf'")
  query = [[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
  SELECT `ancestor`, LAST_INSERT_ID(), `path_length` + 1
  FROM `tree_paths`
  WHERE `descendant` = 7
  UNION ALL
  SELECT LAST_INSERT_ID(), LAST_INSERT_ID(), 0
]]
  db_query(query)

  db_query("INSERT INTO `animals` SET `name` = 'fox'")
  query = [[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
  SELECT `ancestor`, LAST_INSERT_ID(), `path_length` + 1
  FROM `tree_paths`
  WHERE `descendant` = 7
  UNION ALL
  SELECT LAST_INSERT_ID(), LAST_INSERT_ID(), 0
]]
  db_query(query)
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the benchmark queries.
-- Is called during the run command of sysbench.
function benchmark()
  db_query('BEGIN')
  rs = db_query("INSERT INTO `animals` (`id`, `name`) VALUES (11, 'four-legged')")
  rs = db_query("UPDATE `tree_paths` SET `path_length` = `path_length` + 1 WHERE `ancestor` = 1 AND `descendant` != 1")
  rs = db_query([[
INSERT INTO `tree_paths` (`ancestor`, `descendant`, `path_length`)
    SELECT `ancestor`, 11, `path_length` + 1
    FROM `tree_paths`
    WHERE `descendant` = 1
  UNION ALL
    SELECT 11, `descendant`, `path_length` - 1
    FROM `tree_paths`
    WHERE `ancestor` = 1 AND `descendant` != 1
  UNION ALL
    SELECT 11, 11, 0
]])
  db_query('ROLLBACK')
end
