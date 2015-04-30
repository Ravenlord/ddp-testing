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
  `name` VARCHAR(255) NOT NULL,
  `parent_id` INTEGER UNSIGNED,
  CONSTRAINT `fk_animal_parent` FOREIGN KEY (`parent_id`) REFERENCES `animals` (`id`)
)
]]
  db_query(query)
  db_query("INSERT INTO `animals` SET `name` = 'carnivore'")
  db_query("INSERT INTO `animals` SET `name` = 'feline', `parent_id` = 1")
  db_query("INSERT INTO `animals` SET `name` = 'cat', `parent_id` = 2")
  db_query("INSERT INTO `animals` SET `name` = 'big cat', `parent_id` = 2")
  db_query("INSERT INTO `animals` SET `name` = 'tiger', `parent_id` = 4")
  db_query("INSERT INTO `animals` SET `name` = 'lion', `parent_id` = 4")

  db_query("INSERT INTO `animals` SET `name` = 'canine', `parent_id` = 1")
  db_query("INSERT INTO `animals` SET `name` = 'dog', `parent_id` = 7")
  db_query("INSERT INTO `animals` SET `name` = 'wolf', `parent_id` = 7")
  db_query("INSERT INTO `animals` SET `name` = 'fox', `parent_id` = 7")
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the benchmark queries.
-- Is called during the run command of sysbench.
function benchmark()
  db_query('BEGIN')
  rs = db_query("INSERT INTO `animals` (`id`, `name`, `parent_id`) VALUES (11, 'four-legged', 1)")
  rs = db_query("UPDATE `animals` SET `parent_id` = 11 WHERE `parent_id` = 1 AND `id` != 11")
  db_query('ROLLBACK')
end
