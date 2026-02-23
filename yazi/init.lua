-- Custom linemode: size and modification time
function Linemode:size_mtime()
	local size = self._file:size()
	local size_str = size and ya.readable_size(size):gsub("^%s+", "") or "-"

	local time = math.floor(self._file.cha.mtime or 0)
	local time_str
	if time == 0 then
		time_str = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time_str = os.date("%b %d %H:%M", time)
	else
		time_str = os.date("%b %d  %Y", time)
	end

	return string.format(" %7s  %s", size_str, time_str)
end
