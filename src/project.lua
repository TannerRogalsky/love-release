--- Provides tools to manipulate a LÖVE project.
-- @classmod project

local fs = require 'luarocks.fs'
local lr_dir = require 'luarocks.dir'
local class = require 'middleclass'
local utils = require 'love-release.utils'

local Project = class('Project')


--- Title of this project.
Project.title = nil

--- Package name. It's the title converted to lowercase, with alpha-numerical
-- characters and hyphens only.
Project.package = nil

--- LÖVE version the project uses.
Project.loveVersion = nil

--- Version.
Project.version = nil

--- Author full name.
Project.author = nil

--- Email.
Project.email = nil

--- Description.
Project.description = nil

--- Homepage URL.
Project.homepage = nil

--- Uniform Type Identifier in reverse-DNS format.
Project.identifier = nil

--- Project directory, where to find the game sources.
Project.projectDirectory = nil

--- Project release directory, where to store the releases.
Project.releaseDirectory = nil

--- True is the files should be precompiled to LuaJIT bytecode.
Project.compile = false

Project._fileTree = nil
Project._fileList = nil

function Project:initialize()
  local defaultDirectory = fs.current_dir()
  self:setProjectDirectory(defaultDirectory)
  self:setReleaseDirectory(defaultDirectory)
end

--- Recursive function used to build the tree.
-- @local
local _buildFileTree
_buildFileTree = function(dir)
  local subDir
  for file in assert(fs.dir()) do
    if not file:find("^%.git") then
      if fs.is_dir(file) then
        subDir = {}
        dir[file] = subDir
        assert(fs.change_dir(file))
        _buildFileTree(subDir, file)
        assert(fs.pop_dir())
      elseif fs.is_file(file) then
        dir[#dir+1] = file
      end
    end
  end
end

--- Constructs the file tree.
-- @return File tree. The table represents the root directory.
-- Sub-directories are represented as sub-tables, indexed by the directory name.
-- Files are strings stored in each sub-tables.
function Project:fileTree()
  if not self._fileTree then
    assert(fs.change_dir(self.projectDirectory))
    self._fileTree = {}
    _buildFileTree(self._fileTree)
    assert(fs.pop_dir())
  end
  return self._fileTree
end

--- Recursive function used to build the file list.
-- @local
local _buildFileList
_buildFileList = function(list, tree, dir)
  for k, v in pairs(tree) do
    if type(v) == "table" then
      list[#list+1] = dir..k.."/"
      _buildFileList(list, tree[k], dir..k.."/")
    elseif type(v) == "string" then
      list[#list+1] = dir..v
    end
  end
end

--- Constructs the file list.
-- @bool build Rebuild the file tree.
-- @treturn table List of this project's files.
function Project:fileList(build)
  if not self._fileList or build then
    self._fileList = {}
    _buildFileList(self._fileList, self:fileTree(), "")
    self:excludeFiles()
  end
  return self._fileList
end

--- Excludes files from the LÖVE file.
-- @todo This function should be able to parse and use CVS files such as
-- gitignore. It should also work on the file tree rather than on the file list.
-- For now it  works on the file list and only exludes the release directory if
-- it is within the project directory.
function Project:excludeFiles()
  local dir, rm_dir = self.releaseDirectory:gsub(
      "^"..utils.lua.escape_string_regex(self.projectDirectory).."/",
      "")
  if rm_dir > 0 then
    rm_dir = true
    dir = "^"..dir
  else
    rm_dir = false
  end

  if rm_dir then
    local rm = false
    local file
    local n = #self._fileList
    for i = 1, n do
      file = self._fileList[i]
      if rm_dir then if file:find(dir) then rm = true end end
      if rm then
        self._fileList[i] = nil
        rm = false
      end
    end
  end
end

--[[
-- File tree traversal
local function deep(tree)
  for k, v in pairs(tree) do
    if type(v) == "string" then
      print(v)
    elseif type(v) == "table" then
      print(k)
      deep(v)
    end
  end
end
deep(t)
--]]

local function escape(var)
  if type(var) == "string" then
    return "'"..var:gsub("'", "\'").."'"
  else
    return tostring(var)
  end
end

--- Prints debug informations.
-- @local
function Project:__tostring()
  return
  '{\n'..
  '  title = '..escape(self.title)..',\n'..
  '  package = '..escape(self.package)..',\n'..
  '  loveVersion = \''..escape(self.loveVersion)..'\',\n'..
  '  version = '..escape(self.version)..',\n'..
  '  author = '..escape(self.author)..',\n'..
  '  email = '..escape(self.email)..',\n'..
  '  description = '..escape(self.description)..',\n'..
  '  homepage = '..escape(self.homepage)..',\n'..
  '  identifier = '..escape(self.identifier)..',\n'..
  '  compile = '..escape(self.compile)..',\n'..
  '  projectDirectory = '..escape(self.projectDirectory)..',\n'..
  '  releaseDirectory = '..escape(self.releaseDirectory)..',\n'..
  '}'
end

--- Sets the title.
-- @string title the title.
-- @treturn project self.
function Project:setTitle(title)
  self.title = title
  return self
end

--- Sets the package name.
-- @string package the package name.
-- @treturn project self.
function Project:setPackage(package)
  self.package = package
  return self
end

--- Sets the LÖVE version used.
-- @tparam semver version the LÖVE version.
-- @treturn project self.
function Project:setLoveVersion(version)
  self.loveVersion = version
  return self
end

--- Sets the project's version.
-- @string version the version.
-- @treturn project self.
function Project:setVersion(version)
  self.version = version
  return self
end

--- Sets the author.
-- @string author the author.
-- @treturn project self.
function Project:setAuthor(author)
  self.author = author
  return self
end

--- Sets the author's email.
-- @string email the email.
-- @treturn project self.
function Project:setEmail(email)
  self.email = email
  return self
end

--- Sets the description.
-- @string description the description.
-- @treturn project self.
function Project:setDescription(description)
  self.description = description
  return self
end

--- Sets the homepage.
-- @string homepage the homepage.
-- @treturn project self.
function Project:setHomepage(homepage)
  self.homepage = homepage
  return self
end

--- Sets the identifier.
-- @string identifier the identifier.
-- @treturn project self.
function Project:setIdentifier(identifier)
  self.identifier = identifier
  return self
end

--- Sets the source directory. The path is normalized and absoluted.
-- @string directory the directory.
-- @treturn project self.
function Project:setProjectDirectory(directory)
  directory = fs.absolute_name(lr_dir.normalize(directory))
  assert(fs.change_dir(directory))
  fs.pop_dir()
  self.projectDirectory = directory
  return self
end

--- Sets the release directory. The path is normalized and absoluted.
-- @string directory the directory.
-- @treturn project self.
function Project:setReleaseDirectory(directory)
  directory = fs.absolute_name(lr_dir.normalize(directory))
  assert(fs.make_dir(directory))
  assert(fs.change_dir(directory))
  fs.pop_dir()
  self.releaseDirectory = directory
  return self
end

--- Sets if Lua files should be precompiled to LuaJIT bytecode. By default they
-- are not compiled.
-- @bool value wether the files should be compiled or not.
-- @treturn project self
function Project:setCompile(value)
  if value then
    if package.loaded.jit then
      self.compile = true
    else
      assert(fs.is_tool_available("luajit", "LuaJIT", "-v"))
      self.compile = true
    end
  end
end


return Project
