--!nocheck
local Licence = ... or {}
Licence.Key = script_key or Licence.Key

local REPO = "skidforce/catsixextra"
local BRANCH = "main"

local cloneref:(<T>(T) -> T) | (<a>(a) -> a) = cloneref or function(Reference: any) return Reference end
local isfile: (string) -> boolean = isfile or function(File: string): boolean
	local Success: boolean, Result = pcall(function()
		return readfile(File)
	end)

	return Success and Result
end

local HttpService: HttpService = cloneref(game:GetService("HttpService"))

local CryptHash: (Content: string, Algorithm: string) -> string = (crypt and crypt.hash)
if not CryptHash then
	local HashLibrary = loadstring(game:HttpGet(`https://raw.githubusercontent.com/{REPO}/{BRANCH}/libraries/hash.lua`))()
	CryptHash = HashLibrary.sha1
end

local function GetGithubContents(): {Success: boolean, Data: any}
	local Success: boolean, Result: string = pcall(function()
		return game:HttpGet(`https://api.github.com/repos/{REPO}/git/trees/{BRANCH}?recursive=1`)
	end)

	if Success then
		local SuccessfulJSONDecode, JSON = pcall(HttpService.JSONDecode, HttpService, Result)
		if SuccessfulJSONDecode and type(JSON) == 'table' and type(JSON.tree) == 'table' then
			local files = {}
			for _, entry in JSON.tree do
				if entry.type == 'blob' and type(entry.path) == 'string' and not entry.path:find('/profiles/') then
					files[#files + 1] = {
						path = entry.path,
						sha = entry.sha
					}
				end
			end
			return {Success = true, Data = files}
		end
	end

	return {
		Success = false,
		Data = Result
	}
end

local function DownloadAsset(FileData: {path: string}): ()
	local Success: boolean, Content: string = pcall(function()
		return game:HttpGet(`https://raw.githubusercontent.com/{REPO}/{BRANCH}/{FileData.path:gsub("^src/", "")}`)
	end)

	if Success then
		writefile(`catsixextra/{FileData.path:gsub("^src/", "")}`, Content)
	end
end

local function GetCurrentSHA(Path: string): string
	local FilePath: string = `catsixextra/{Path:gsub("^src/", "")}`
	local FileContents = (isfile(FilePath) and readfile(FilePath))
	if FileContents then
		return CryptHash(`blob {#FileContents}\0{FileContents}`, "sha1")
	end

	return ""
end

local function DownloadAssets(Contents: {Success: boolean, Data: any}): boolean
	if Contents.Success then
		for _, v in Contents.Data do
			local CurrentSHA: string = GetCurrentSHA(v.path)
			if CurrentSHA ~= v.sha then
				DownloadAsset(v)
			end
		end
	end

	return Contents.Success
end

for _, Folder: string in {'catsixextra', 'catsixextra/games', 'catsixextra/profiles', 'catsixextra/assets', 'catsixextra/libraries', 'catsixextra/guis'} do
	if not isfolder(Folder) then
		makefolder(Folder)
	end
end

if not shared.VapeDeveloper then
	local Commit: string? = Licence.Commit
	if not Commit then
		local Success: boolean, Result: string = pcall(function()
			return game:HttpGet(`https://api.github.com/repos/{REPO}/commits/{BRANCH}`)
		end)

		if Success then
			local SuccessJSON, JSON = pcall(HttpService.JSONDecode, HttpService, Result)
			if SuccessJSON and type(JSON) == 'table' and type(JSON.sha) == 'string' then
				Commit = JSON.sha
			end
		end
	end

	if not isfile('catsixextra/profiles/commit.txt') or readfile('catsixextra/profiles/commit.txt') ~= Commit then
		local Success: boolean = DownloadAssets(GetGithubContents())
		if not Success then
			warn(`Failed to update to {Commit}`)
		else
			warn(`Successfully updated to {Commit}`)
		end

		writefile('catsixextra/profiles/commit.txt', Commit)
	end
end

return loadstring(readfile('catsixextra/main.lua'), 'main')(Licence)